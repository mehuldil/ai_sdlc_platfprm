#!/usr/bin/env python3
"""
Composition Engine - Executes composed skills from YAML definitions.

Transforms declarative skill compositions into executable workflows.
"""

import argparse
import asyncio
import json
import logging
import os
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Callable

import yaml

logger = logging.getLogger(__name__)


@dataclass
class StepResult:
    """Result of executing a composition step."""
    step_id: str
    success: bool
    output: Any
    error: Optional[str] = None
    duration_ms: int = 0
    cached: bool = False


class CompositionEngine:
    """
    Engine for executing composed skill workflows.
    
    Features:
    - Variable interpolation ($var, ${expression})
    - Step dependencies and parallel execution
    - Error handling and retries
    - Caching
    - Gate checkpoints
    """
    
    def __init__(self, platform_dir: str, project_dir: str):
        self.platform_dir = Path(platform_dir)
        self.project_dir = Path(project_dir)
        self.cache_dir = Path(project_dir) / ".sdlc" / "cache" / "skills"
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        
        # Step outputs for variable interpolation
        self.step_outputs: Dict[str, Any] = {}
        self.context: Dict[str, Any] = {}
        
    def load_composition(self, composition_path: str) -> Dict:
        """Load composition from YAML file."""
        with open(composition_path, 'r') as f:
            return yaml.safe_load(f)
            
    def interpolate(self, value: Any, step_outputs: Dict[str, Any]) -> Any:
        """
        Interpolate variables in value.
        
        Supports:
        - $var - Simple variable
        - ${expression} - Complex expression
        - ${step.output.field} - Step output access
        """
        if isinstance(value, str):
            # Pattern: $var or ${expression}
            patterns = [
                (r'\$\{([^}]+)\}', self._eval_expression),
                (r'\$([a-zA-Z_][a-zA-Z0-9_]*)', self._get_simple_var),
            ]
            
            result = value
            for pattern, handler in patterns:
                def replacer(match):
                    return handler(match.group(1), step_outputs)
                result = re.sub(pattern, replacer, result)
                
            return result
            
        elif isinstance(value, list):
            return [self.interpolate(item, step_outputs) for item in value]
            
        elif isinstance(value, dict):
            return {
                k: self.interpolate(v, step_outputs)
                for k, v in value.items()
            }
            
        return value
        
    def _get_simple_var(self, var_name: str, step_outputs: Dict) -> str:
        """Get simple variable value."""
        if var_name in step_outputs:
            val = step_outputs[var_name]
            return json.dumps(val) if not isinstance(val, str) else val
        if var_name in self.context:
            val = self.context[var_name]
            return json.dumps(val) if not isinstance(val, str) else val
        return f"${var_name}"  # Keep as-is if not found
        
    def _eval_expression(self, expr: str, step_outputs: Dict) -> str:
        """Evaluate complex expression."""
        # Handle step output access: step-1.output.field
        if '.' in expr:
            parts = expr.split('.')
            value = step_outputs
            
            for part in parts:
                if isinstance(value, dict):
                    value = value.get(part, {})
                else:
                    return f"${{{expr}}}"
                    
            return json.dumps(value) if not isinstance(value, str) else value
            
        # Simple variable
        return self._get_simple_var(expr, step_outputs)
        
    async def execute_step(
        self,
        step: Dict,
        composition: Dict
    ) -> StepResult:
        """Execute a single composition step."""
        step_id = step['id']
        skill = step['skill']
        
        logger.info(f"Executing step: {step_id} (skill: {skill})")
        
        start_time = datetime.utcnow()
        
        try:
            # Interpolate inputs
            raw_input = step.get('input', {})
            interpolated_input = self.interpolate(raw_input, self.step_outputs)
            
            logger.debug(f"Step {step_id} input: {json.dumps(interpolated_input, indent=2)}")
            
            # Check cache
            cache_key = self._get_cache_key(step_id, interpolated_input)
            cache_file = self.cache_dir / f"{cache_key}.json"
            
            ttl = step.get('cache', {}).get('ttl', 0)
            if ttl > 0 and cache_file.exists():
                age = (datetime.utcnow().timestamp() - cache_file.stat().st_mtime)
                if age < ttl:
                    logger.info(f"Cache hit for step {step_id}")
                    with open(cache_file, 'r') as f:
                        cached_result = json.load(f)
                    
                    self.step_outputs[step_id] = cached_result
                    
                    duration = int((datetime.utcnow() - start_time).total_seconds() * 1000)
                    return StepResult(
                        step_id=step_id,
                        success=True,
                        output=cached_result,
                        duration_ms=duration,
                        cached=True
                    )
            
            # Execute skill
            output = await self._execute_skill(skill, interpolated_input, step)
            
            # Store output
            self.step_outputs[step_id] = output
            
            # Cache result
            if ttl > 0:
                with open(cache_file, 'w') as f:
                    json.dump(output, f)
                    
            duration = int((datetime.utcnow() - start_time).total_seconds() * 1000)
            
            logger.info(f"Step {step_id} completed in {duration}ms")
            
            return StepResult(
                step_id=step_id,
                success=True,
                output=output,
                duration_ms=duration
            )
            
        except Exception as e:
            logger.error(f"Step {step_id} failed: {e}")
            
            # Handle error according to step config
            on_error = step.get('on_error', 'fail')
            
            if on_error == 'continue_with_warning':
                logger.warning(f"Continuing after error in {step_id}")
                self.step_outputs[step_id] = {"error": str(e), "warning": True}
                return StepResult(
                    step_id=step_id,
                    success=True,  # Considered success
                    output={"error": str(e)},
                    error=str(e)
                )
            elif on_error == 'retry_once':
                logger.info(f"Retrying {step_id}...")
                # Simple retry
                try:
                    output = await self._execute_skill(skill, interpolated_input, step)
                    self.step_outputs[step_id] = output
                    return StepResult(step_id=step_id, success=True, output=output)
                except Exception as e2:
                    return StepResult(step_id=step_id, success=False, error=str(e2))
            else:
                return StepResult(step_id=step_id, success=False, error=str(e))
                
    async def _execute_skill(
        self,
        skill: str,
        input_data: Dict,
        step_config: Dict
    ) -> Any:
        """Execute a single skill."""
        # Route to skill implementation
        # This would call the actual skill execution logic
        
        # For now, simulate skill execution
        logger.debug(f"Executing skill {skill} with input: {input_data}")
        
        # Map atomic skills to their implementations
        atomic_skills_dir = self.platform_dir / "skills" / "atomic"
        skill_file = atomic_skills_dir / f"{skill}.md"
        
        if skill_file.exists():
            # Atomic skill found
            return await self._execute_atomic_skill(skill, skill_file, input_data)
        else:
            # Try to execute via shell command
            return await self._execute_shell_skill(skill, input_data)
            
    async def _execute_atomic_skill(
        self,
        skill: str,
        skill_file: Path,
        input_data: Dict
    ) -> Dict:
        """Execute an atomic skill from markdown definition."""
        # Parse skill definition
        with open(skill_file, 'r') as f:
            content = f.read()
            
        # Look for bash execution block
        bash_match = re.search(
            r'```bash\n(.*?)```',
            content,
            re.DOTALL
        )
        
        if not bash_match:
            return {"skill": skill, "executed": True, "output": "No bash block found"}
            
        script = bash_match.group(1)
        
        # Create temporary script
        import tempfile
        import subprocess
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.sh', delete=False) as f:
            # Write environment variables
            for key, value in input_data.items():
                if isinstance(value, str):
                    f.write(f'{key}="{value}"\n')
                else:
                    f.write(f'{key}=\'{json.dumps(value)}\'\n')
                    
            f.write(script)
            script_path = f.name
            
        try:
            # Execute script
            result = subprocess.run(
                ['bash', script_path],
                capture_output=True,
                text=True,
                timeout=30,
                cwd=self.project_dir
            )
            
            # Try to parse output as JSON
            try:
                output = json.loads(result.stdout)
            except json.JSONDecodeError:
                output = {"stdout": result.stdout, "stderr": result.stderr}
                
            return output
            
        finally:
            os.unlink(script_path)
            
    async def _execute_shell_skill(self, skill: str, input_data: Dict) -> Dict:
        """Execute skill via shell command."""
        # This would delegate to the existing skill execution
        import subprocess
        
        cmd = [
            "bash",
            str(self.platform_dir / "cli" / "sdlc.sh"),
            "skills",
            "invoke",
            skill,
            "--input",
            json.dumps(input_data)
        ]
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300,
            cwd=self.project_dir
        )
        
        try:
            return json.loads(result.stdout)
        except:
            return {"stdout": result.stdout, "stderr": result.stderr}
            
    def _get_cache_key(self, step_id: str, input_data: Dict) -> str:
        """Generate cache key for step."""
        data = f"{step_id}:{json.dumps(input_data, sort_keys=True)}"
        return hashlib.sha256(data.encode()).hexdigest()[:16]
        
    async def execute_composition(
        self,
        composition: Dict,
        context: Optional[Dict] = None
    ) -> Dict:
        """Execute full composition."""
        logger.info(f"Executing composition: {composition.get('name', 'unnamed')}")
        
        self.context = context or {}
        self.step_outputs = {}
        
        steps = composition.get('composition', [])
        results: List[StepResult] = []
        
        # Build dependency graph
        step_map = {s['id']: s for s in steps}
        executed = set()
        
        async def execute_with_deps(step: Dict):
            """Execute step after its dependencies."""
            step_id = step['id']
            
            if step_id in executed:
                return
                
            # Wait for dependencies
            deps = step.get('depends_on', [])
            for dep_id in deps:
                if dep_id not in executed:
                    if dep_id in step_map:
                        await execute_with_deps(step_map[dep_id])
                    else:
                        logger.error(f"Dependency {dep_id} not found")
                        
            # Execute this step
            result = await self.execute_step(step, composition)
            results.append(result)
            executed.add(step_id)
            
            if not result.success:
                # Check if we should continue
                on_error = step.get('on_error', 'fail')
                if on_error == 'fail':
                    raise Exception(f"Step {step_id} failed: {result.error}")
                    
        # Execute all steps
        for step in steps:
            await execute_with_deps(step)
            
        # Handle gate if present
        gate_result = None
        if 'gate' in composition:
            gate_result = await self._handle_gate(composition['gate'])
            
        # Execute ADO actions
        if 'ado_actions' in composition:
            await self._handle_ado_actions(composition['ado_actions'], results)
            
        # Return final output
        final_step = steps[-1] if steps else None
        final_output = self.step_outputs.get(final_step['id'], {}) if final_step else {}
        
        return {
            "composition": composition.get('name'),
            "success": all(r.success for r in results),
            "steps": [
                {
                    "id": r.step_id,
                    "success": r.success,
                    "duration_ms": r.duration_ms,
                    "cached": r.cached,
                    "error": r.error
                }
                for r in results
            ],
            "output": final_output,
            "gate_result": gate_result
        }
        
    async def _handle_gate(self, gate_config: Dict) -> Dict:
        """Handle gate checkpoint."""
        logger.info(f"Gate checkpoint: {gate_config.get('id', 'unnamed')}")
        
        # Interpolate gate prompt
        prompt = self.interpolate(gate_config.get('prompt', ''), self.step_outputs)
        
        # In real implementation, this would:
        # 1. Present prompt to user
        # 2. Wait for response
        # 3. Handle decision
        
        # For now, simulate approval
        logger.info(f"Gate prompt: {prompt[:100]}...")
        
        return {
            "gate_id": gate_config.get('id'),
            "status": "approved",
            "timestamp": datetime.utcnow().isoformat()
        }
        
    async def _handle_ado_actions(
        self,
        actions_config: Dict,
        results: List[StepResult]
    ):
        """Handle ADO integration actions."""
        on_complete = actions_config.get('on_complete', [])
        
        for action in on_complete:
            action_type = action.get('action')
            
            if action_type == 'add_comment':
                text = self.interpolate(action.get('text', ''), self.step_outputs)
                logger.info(f"Would add ADO comment: {text[:100]}...")
                
            elif action_type == 'add_tags':
                tags = action.get('tags', [])
                logger.info(f"Would add ADO tags: {tags}")


async def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(description='Execute composed skill')
    parser.add_argument('--composition', required=True, help='Path to composition YAML')
    parser.add_argument('--input', default='{}', help='JSON input data')
    parser.add_argument('--platform-dir', default='.', help='Platform directory')
    parser.add_argument('--project-dir', default='.', help='Project directory')
    
    args = parser.parse_args()
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    engine = CompositionEngine(args.platform_dir, args.project_dir)
    composition = engine.load_composition(args.composition)
    context = json.loads(args.input)
    
    result = await engine.execute_composition(composition, context)
    
    print(json.dumps(result, indent=2))
    
    sys.exit(0 if result['success'] else 1)


if __name__ == '__main__':
    asyncio.run(main())
