/**
 * Context Loader Hook
 *
 * Auto-loads .sdlc/memory context on plugin startup
 * Provides session continuity and previous stage decisions
 *
 * Triggers on:
 * - Plugin initialization
 * - New chat message (checks for story reference)
 * - /project commands (auto-loads relevant memory)
 */

const fs = require('fs');
const path = require('path');

/**
 * Load memory files for current project/story
 *
 * @param {string} projectRoot - Project root directory
 * @param {string} storyId - Story ID (optional, e.g., US-1234)
 * @returns {Promise<Object>} Loaded memory context
 */
async function loadMemoryContext(projectRoot, storyId = null) {
  const memoryPath = path.join(projectRoot, '.sdlc', 'memory');

  // Check if memory directory exists
  if (!fs.existsSync(memoryPath)) {
    return {
      loaded: false,
      message: 'No .sdlc/memory directory found'
    };
  }

  try {
    const context = {
      loaded: true,
      timestamp: new Date().toISOString(),
      memory: {}
    };

    // Load all memory files
    const files = fs.readdirSync(memoryPath);

    for (const file of files) {
      if (file.endsWith('.md') || file.endsWith('.json')) {
        const filePath = path.join(memoryPath, file);
        const content = fs.readFileSync(filePath, 'utf-8');

        // Parse JSON files
        if (file.endsWith('.json')) {
          try {
            context.memory[file.replace('.json', '')] = JSON.parse(content);
          } catch (e) {
            context.memory[file.replace('.json', '')] = content;
          }
        } else {
          // Keep markdown as-is
          context.memory[file.replace('.md', '')] = content;
        }
      }
    }

    // If storyId provided, load story-specific memory
    if (storyId) {
      const storyMemory = loadStoryMemory(memoryPath, storyId);
      context.story = storyMemory;
    }

    // Load project configuration
    const configPath = path.join(projectRoot, '.sdlc', 'config');
    if (fs.existsSync(configPath)) {
      context.config = JSON.parse(
        fs.readFileSync(configPath, 'utf-8')
      );
    }

    // Load state for current session
    const statePath = path.join(projectRoot, '.sdlc', 'state.json');
    if (fs.existsSync(statePath)) {
      context.state = JSON.parse(
        fs.readFileSync(statePath, 'utf-8')
      );
    }

    return context;
  } catch (error) {
    return {
      loaded: false,
      error: error.message,
      message: `Failed to load memory: ${error.message}`
    };
  }
}

/**
 * Load story-specific memory (previous stages)
 *
 * @param {string} memoryPath - Path to memory directory
 * @param {string} storyId - Story ID
 * @returns {Object} Story memory context
 */
function loadStoryMemory(memoryPath, storyId) {
  const storyMemory = {};

  try {
    const files = fs.readdirSync(memoryPath);

    // Find all files related to this story
    const storyFiles = files.filter(f =>
      f.includes(storyId) || f.includes(storyId.replace(/[#]/g, ''))
    );

    storyFiles.forEach(file => {
      const filePath = path.join(memoryPath, file);
      const content = fs.readFileSync(filePath, 'utf-8');

      if (file.endsWith('.json')) {
        try {
          storyMemory[file.replace('.json', '')] = JSON.parse(content);
        } catch (e) {
          storyMemory[file.replace('.json', '')] = content;
        }
      } else {
        storyMemory[file.replace('.md', '')] = content;
      }
    });
  } catch (error) {
    storyMemory.error = error.message;
  }

  return storyMemory;
}

/**
 * Save memory context (called after each stage completion)
 *
 * @param {string} projectRoot - Project root directory
 * @param {string} stageName - Stage name (e.g., '02-prd-review')
 * @param {Object} data - Data to save
 * @returns {Promise<boolean>} Success/failure
 */
async function saveMemory(projectRoot, stageName, data) {
  try {
    const memoryPath = path.join(projectRoot, '.sdlc', 'memory');

    // Create directory if not exists
    if (!fs.existsSync(memoryPath)) {
      fs.mkdirSync(memoryPath, { recursive: true });
    }

    const fileName = `${stageName}-completion.json`;
    const filePath = path.join(memoryPath, fileName);

    // Add metadata
    const memoryData = {
      stage: stageName,
      savedAt: new Date().toISOString(),
      data: data
    };

    fs.writeFileSync(
      filePath,
      JSON.stringify(memoryData, null, 2),
      'utf-8'
    );

    return true;
  } catch (error) {
    console.error(`Failed to save memory for ${stageName}:`, error.message);
    return false;
  }
}

/**
 * Extract context from chat message
 * Detects story ID or project reference
 *
 * @param {string} message - Chat message
 * @returns {Object} Extracted context (storyId, command, etc.)
 */
function extractContextFromMessage(message) {
  const context = {};

  // Look for story ID (e.g., AB#123, US-1234, etc.)
  const storyIdMatch = message.match(/(AB#|US#)?(\d{4,6})/);
  if (storyIdMatch) {
    context.storyId = storyIdMatch[0];
  }

  // Look for /project: commands
  const commandMatch = message.match(/\/project:(\w+)/);
  if (commandMatch) {
    context.command = commandMatch[1];
  }

  // Look for role references
  const roleMatch = message.match(/--role=(\w+)/);
  if (roleMatch) {
    context.role = roleMatch[1];
  }

  // Look for sprint references
  const sprintMatch = message.match(/--sprint=(\d+)/);
  if (sprintMatch) {
    context.sprint = sprintMatch[1];
  }

  return context;
}

/**
 * Initialize plugin context on startup
 *
 * Called when plugin loads in IDE
 * Establishes baseline context for all operations
 *
 * @param {string} projectRoot - Current project root
 * @returns {Promise<Object>} Initialized context
 */
async function initializePluginContext(projectRoot) {
  try {
    const context = {
      projectRoot,
      initialized: true,
      timestamp: new Date().toISOString(),
      memory: {},
      config: {}
    };

    // Load project memory
    const memoryContext = await loadMemoryContext(projectRoot);
    context.memory = memoryContext.memory;

    // Load configuration
    const configPath = path.join(projectRoot, '.sdlc', 'config');
    if (fs.existsSync(configPath)) {
      context.config = JSON.parse(
        fs.readFileSync(configPath, 'utf-8')
      );
    }

    // Load current session state
    const statePath = path.join(projectRoot, '.sdlc', 'state.json');
    if (fs.existsSync(statePath)) {
      context.state = JSON.parse(
        fs.readFileSync(statePath, 'utf-8')
      );
    }

    return context;
  } catch (error) {
    return {
      initialized: false,
      error: error.message
    };
  }
}

module.exports = {
  loadMemoryContext,
  loadStoryMemory,
  saveMemory,
  extractContextFromMessage,
  initializePluginContext
};
