#
# PowerShell tab-completion for sdlc CLI
# Add this to your PowerShell profile (usually $PROFILE):
#   . "C:\path\to\sdlc-platform\cli\completions\sdlc.ps1"
#

using namespace System.Management.Automation
using namespace System.Management.Automation.Language

$scriptBlock = {
  param($wordToComplete, $commandAst, $cursorPosition)

  $tokens = $commandAst.ToString().Split(' ')
  $commandCount = 0

  foreach ($token in $tokens) {
    if ($token -ne 'sdlc') {
      $commandCount += 1
    }
    if ($commandCount -eq 1) {
      $firstCommand = $token
      break
    }
  }

  $roles = @('product', 'backend', 'frontend', 'ui', 'tpm', 'qa', 'perf', 'boss')
  $stages = @('intake', 'prd', 'pregroom', 'groom', 'design', 'design-review', 'tasks',
              'impl', 'review', 'test-design', 'test-exec', 'commit', 'docs', 'release', 'close')
  $stacks = @('java', 'kotlin-android', 'swift-ios', 'react-native', 'jmeter', 'figma-design')
  $workflows = @('full-sdlc', 'dev-cycle', 'quick-fix', 'test-cycle', 'prd-to-stories',
                 'perf-cycle', 'design-cycle', 'boss-report')
  $commands = @('role', 'stage', 'run', 'workflow', 'context', 'status', 'resume',
                'memory', 'list', 'help')
  $listEntities = @('stages', 'roles', 'stacks', 'workflows')
  $memorySubcommands = @('sync', 'publish')

  $completions = @()

  # Determine what to complete based on position
  if ($commandCount -eq 0 -or ($wordToComplete -eq '' -and $commandCount -eq 0)) {
    # Complete main commands
    $completions = $commands
  }
  elseif ($commandCount -eq 1) {
    # Second argument depends on the first command
    switch ($firstCommand) {
      'role' {
        $completions = $roles
      }
      'stage' {
        $completions = $stages
      }
      'run' {
        $completions = $stages
      }
      'workflow' {
        $completions = $workflows
      }
      'list' {
        $completions = $listEntities
      }
      'memory' {
        $completions = $memorySubcommands
      }
      default {
        $completions = @()
      }
    }
  }
  elseif ($commandCount -ge 2 -and $firstCommand -eq 'run') {
    # Handle 'run' command options
    if ($wordToComplete.StartsWith('--')) {
      $options = @('--story=', '--task=', '--stack=', '--role=')
      $completions = $options | Where-Object { $_.StartsWith($wordToComplete) }
    }
    elseif ($tokens[-2] -like '--stack=*' -or $tokens[-2] -eq '--stack') {
      $completions = $stacks
    }
    elseif ($tokens[-2] -like '--role=*' -or $tokens[-2] -eq '--role') {
      $completions = $roles
    }
  }

  # Generate completion results
  $completions |
    Where-Object { $_ -like "$wordToComplete*" } |
    ForEach-Object {
      [CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -CommandName sdlc -ScriptBlock $scriptBlock
