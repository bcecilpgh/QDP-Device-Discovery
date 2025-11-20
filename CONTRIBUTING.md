# Contributing to QSC Device Discovery Plugin

First off, thank you for considering contributing to the QSC Device Discovery Plugin! It's people like you that make this plugin better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Enhancements](#suggesting-enhancements)

---

## Code of Conduct

This project and everyone participating in it is governed by our commitment to creating a welcoming and inclusive environment. We expect all contributors to:

- Be respectful and constructive in all interactions
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

---

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

**Bug Report Template:**

```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
A clear description of what you expected to happen.

**Environment:**
- Q-SYS Designer Version: [e.g. 9.10.2]
- Plugin Version: [e.g. 2.0]
- OS: [e.g. Windows 11]
- Network Configuration: [e.g. subnet, VLAN info]

**Debug Log**
Paste relevant debug log output from Q-SYS Designer

**Additional context**
Add any other context about the problem here.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful** to most users
- **List any alternatives** you've considered
- **Include examples** of how the feature would work

---

## Development Setup

### Prerequisites

- Q-SYS Designer (latest version recommended)
- Text editor with Lua support (VS Code recommended)
- Git for version control

### Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/qsc-device-discovery.git
   cd qsc-device-discovery
   ```
3. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make your changes** to the `.qplug` file
5. **Test in Q-SYS Designer**:
   - Copy the modified `.qplug` file to your Plugins folder
   - Restart Q-SYS Designer if necessary
   - Test all functionality thoroughly

---

## Coding Guidelines

### Lua Style

Follow these conventions when writing Lua code:

**Indentation:**
- Use 2 spaces for indentation (not tabs)
- Indent function bodies and control structures

**Naming:**
- `PascalCase` for functions: `function StartDiscovery()`
- `snake_case` for variables: `local discovered_devices = {}`
- `UPPER_CASE` for constants: `local DISCOVERY_PORT = 2467`

**Comments:**
- Add comments for complex logic
- Use `--` for single-line comments
- Use `--[[  ]]` for multi-line comments

**Example:**

```lua
-- Good
function ParseQDPPacket(data)
  local device_info = {}
  
  -- Extract hostname from XML
  local name = string.match(data, "<n>([^<]+)</n>")
  if name then
    device_info.hostname = name
  end
  
  return device_info
end

-- Bad
function parse_qdp(d)
local di={}
local n=string.match(d,"<n>([^<]+)</n>")
if n then di.hostname=n end
return di
end
```

### Plugin Structure

Maintain the existing structure:

1. **PluginInfo** - Metadata (update version on changes)
2. **GetColor()** - UI color scheme
3. **GetPrettyName()** - Display name
4. **GetProperties()** - Configuration properties
5. **GetControls()** - Control definitions
6. **GetControlLayout()** - UI layout
7. **Runtime Code** - Main logic in `if Controls then` block

### Debug Logging

Always add debug logging for new features:

```lua
function DebugPrint(message)
  if DEBUG then
    print("[QSC Discovery] " .. message)
  end
end

-- Use throughout code
DebugPrint("Starting discovery scan")
DebugPrint("Parsed hostname: " .. hostname)
```

### Error Handling

Wrap operations that might fail in `pcall()`:

```lua
local success, err = pcall(function()
  udp_socket:Open("0.0.0.0", 2467)
end)

if not success then
  DebugPrint("ERROR: " .. tostring(err))
  Controls.status.Value = 5
  Controls.status.String = "Error: " .. tostring(err)
  return
end
```

---

## Commit Messages

Write clear, descriptive commit messages:

### Format

```
<type>: <subject>

<body>

<footer>
```

### Types

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, no logic change)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

### Examples

**Good:**
```
feat: add CSV export functionality

Implement CSV export for discovered devices list.
Export includes hostname, IP, part number, and type.
Accessible via new Export button in UI.

Closes #42
```

**Bad:**
```
fixed stuff
```

---

## Pull Request Process

1. **Update documentation** if you're adding features or changing behavior
2. **Test thoroughly** in Q-SYS Designer with various scenarios
3. **Update the README.md** with details of changes if applicable
4. **Update version numbers** following [Semantic Versioning](http://semver.org/)
5. **Add yourself** to the contributors list if you'd like

### PR Template

When submitting a PR, include:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
Describe how you tested your changes:
- [ ] Tested in Q-SYS Designer
- [ ] Tested with multiple devices
- [ ] Tested filter functionality
- [ ] Checked debug logging

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have updated the documentation accordingly
- [ ] My changes generate no new warnings or errors
- [ ] I have added debug logging for new features
```

---

## Testing

### Manual Testing Checklist

Before submitting, test the following:

**Basic Functionality:**
- [ ] Plugin loads without errors
- [ ] Scan button triggers discovery
- [ ] Devices appear in list
- [ ] Status indicator updates correctly
- [ ] Timer expires after 15 seconds
- [ ] Socket closes properly

**Filter Testing:**
- [ ] Filters work with hostname matching
- [ ] Filters work with IP matching
- [ ] Filters work with part number matching
- [ ] Multiple filters work together
- [ ] Changing filters updates list immediately
- [ ] Empty filters show all devices

**Edge Cases:**
- [ ] No devices on network
- [ ] Port 2467 already in use
- [ ] Network disconnected during scan
- [ ] Multiple rapid scans
- [ ] All devices filtered out

**Debug Logging:**
- [ ] All major operations logged
- [ ] Error conditions logged
- [ ] Packet data logged at appropriate detail

---

## Documentation

When adding features, update:

1. **README.md** - User-facing features and usage
2. **Technical Documentation** - Implementation details
3. **User Manual** - End-user instructions
4. **Inline Comments** - Code-level documentation

---

## Questions?

Don't hesitate to ask questions:
- Open an issue with the `question` label
- Reach out to the maintainers
- Check existing documentation

---

## Attribution

This Contributing guide is adapted from open-source projects and best practices.

Thank you for contributing to QSC Device Discovery Plugin!
