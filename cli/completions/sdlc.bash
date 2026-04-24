#!/bin/bash

# Bash completion script for sdlc CLI
# Source this in your ~/.bashrc or ~/.bash_profile:
#   source /path/to/ai-sdlc-platform/cli/completions/sdlc.bash

_sdlc_completions() {
  local cur prev words cword
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  words=("${COMP_WORDS[@]}")
  cword=$COMP_CWORD

  # Main commands
  local main_commands="init use context run flow sync publish memory status resume stages roles stacks route ado tokens doctor help version"

  # Available roles
  local roles="product backend frontend ui tpm qa performance boss"

  # Available stages
  local stages="01-requirement-intake 02-prd-review 03-pre-grooming 04-grooming 05-system-design 06-design-review 07-task-breakdown 08-implementation 09-code-review 10-test-design 11-test-execution 12-commit-push 13-documentation 14-release-signoff 15-summary-close"

  # Available stacks
  local stacks="java kotlin-android swift-ios react-native jmeter figma-design"

  # Available workflows
  local workflows="dev-cycle full-sdlc test-cycle prd-to-stories perf-cycle design-cycle boss-report"

  # ADO subcommands
  local ado_subcommands="create list show update link push-story"

  # ADO create types
  local ado_types="epic feature story task bug testcase testplan"

  # Main command completion
  if [[ $cword -eq 1 ]]; then
    COMPREPLY=($(compgen -W "${main_commands}" -- ${cur}))
    return 0
  fi

  # Context-specific completions based on first argument
  local first_cmd="${words[1]}"

  case "$first_cmd" in
    init)
      # Init command options
      if [[ ${cur} == --* ]]; then
        COMPREPLY=($(compgen -W "--git --local" -- ${cur}))
      fi
      ;;
    use)
      # Role completion for "use" command
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "${roles}" -- ${cur}))
      elif [[ ${cur} == --stack=* ]]; then
        local stack_prefix="${cur#--stack=}"
        local completions=$(compgen -W "${stacks}" -- ${stack_prefix})
        COMPREPLY=($(echo "$completions" | sed "s/^/--stack=/"))
      fi
      ;;
    run)
      # Stage completion for "run" command
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "${stages}" -- ${cur}))
      elif [[ ${cur} == --story=* ]]; then
        # User provides story ID
        COMPREPLY=()
      elif [[ ${cur} == --from=* ]]; then
        local stage_prefix="${cur#--from=}"
        local completions=$(compgen -W "${stages}" -- ${stage_prefix})
        COMPREPLY=($(echo "$completions" | sed "s/^/--from=/"))
      elif [[ ${cur} == --to=* ]]; then
        local stage_prefix="${cur#--to=}"
        local completions=$(compgen -W "${stages}" -- ${stage_prefix})
        COMPREPLY=($(echo "$completions" | sed "s/^/--to=/"))
      elif [[ ${cur} == -* ]]; then
        COMPREPLY=($(compgen -W "--story= --from= --to=" -- ${cur}))
      fi
      ;;
    flow)
      # Workflow completion for "flow" command
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "${workflows} list" -- ${cur}))
      fi
      ;;
    memory)
      # Memory subcommand completion
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "sync publish show" -- ${cur}))
      fi
      ;;
    route)
      # Route command - accepts task description as argument (no specific completions)
      COMPREPLY=()
      ;;
    doctor)
      # Doctor command - validation and diagnostics (no specific completions)
      COMPREPLY=()
      ;;
    ado)
      # ADO subcommand completion
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "${ado_subcommands}" -- ${cur}))
      elif [[ $cword -gt 2 ]]; then
        local ado_cmd="${words[2]}"
        case "$ado_cmd" in
          create)
            # ADO create type completion
            if [[ $cword -eq 3 ]]; then
              COMPREPLY=($(compgen -W "${ado_types}" -- ${cur}))
            elif [[ ${cur} == --* ]]; then
              COMPREPLY=($(compgen -W "--title= --assignee= --parent= --description=" -- ${cur}))
            fi
            ;;
          list)
            # ADO list options
            if [[ ${cur} == --* ]]; then
              COMPREPLY=($(compgen -W "--type= --state= --team=" -- ${cur}))
            fi
            ;;
          show)
            # ADO show - accepts work item ID (no completion)
            COMPREPLY=()
            ;;
          update)
            # ADO update - accepts work item ID
            if [[ $cword -eq 3 ]]; then
              COMPREPLY=()
            elif [[ ${cur} == --* ]]; then
              COMPREPLY=($(compgen -W "--title= --state= --assignee=" -- ${cur}))
            fi
            ;;
          link)
            # ADO link - accepts work item IDs
            COMPREPLY=()
            ;;
          push-story)
            # ADO push-story - accepts file path
            COMPREPLY=()
            ;;
        esac
      fi
      ;;
    tokens)
      # Tokens command - show usage (no specific completions)
      if [[ ${cur} == --* ]]; then
        COMPREPLY=($(compgen -W "--team= --sprint= --reset" -- ${cur}))
      fi
      ;;
  esac

  return 0
}

# Register the completion function
complete -o bashdefault -o default -o nospace -F _sdlc_completions sdlc
