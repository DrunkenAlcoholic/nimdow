import 
  x11 / xlib,
  parsetoml,
  tables,
  "../keys/keyutils"

type KeyCombo* =
  tuple[keycode: int, modifiers: int] 

# TODO: value of this table should be "proc".
# Need to find a way to map a string repr of a proc to the proc itself.
var ConfigTable* = tables.initTable[KeyCombo, string]()

proc getModifierMask(modifier: TomlValueRef): int =
  if modifier.kind != TomlValueKind.String:
    raise newException(Exception, "Invalid key configuration: " &
                       repr(modifier) & " is not a string")
  if not ModifierTable.hasKey(modifier.stringVal):
    raise newException(Exception, "Invalid key configuration: " & 
                       repr(modifier) & " is not a a valid key modifier")
  return ModifierTable[modifier.stringVal]

proc xorModifiers(modifiers: openarray[TomlValueRef]): int =
  for tomlElement in modifiers:
    result = result or getModifierMask(tomlElement)

proc getKeyForAction(configTable: TomlTable, action: string): string =
  var keyConfig = configTable[action]["key"]
  if keyConfig.kind != TomlValueKind.String:
    raise newException(Exception, "Invalid key configuration: " &
                       repr(keyConfig) & " is not a string")
  return keyConfig.stringVal

proc getModifiersForAction(configTable: TomlTable, action: string): seq[TomlValueRef] =
  var modifiersConfig = configTable[action]["modifiers"]
  if modifiersConfig.kind != TomlValueKind.Array:
    raise newException(Exception, "Invalid key configuration: " &
                       repr(modifiersConfig) & " is not an array")
  return modifiersConfig.arrayVal

proc getKeyCombo(configTable: TomlTable, display: PDisplay, action: string): KeyCombo =
  ## Gets the KeyCombo associated with the given `action` from the table.
  let key: string = configTable.getKeyForAction(action)
  let modifierArray = configTable.getModifiersForAction(action)
  let modifiers: int = xorModifiers(modifierArray)
  let keycode: int = key.toKeycode(display)
  return (keycode, modifiers)

proc populateAction(display: PDisplay, action: string, configTable: TomlTable) =
  let keyCombo = configTable.getKeyCombo(display, action)
  ConfigTable[keyCombo] = action

proc loadConfigfile(configPath: string): TomlTable =
  ## Reads the user's configuration file into a table.
  let loadedConfig = parsetoml.parseFile(configPath)
  if loadedConfig.kind != TomlValueKind.Table:
    raise newException(Exception, "Invalid key configuration!")
  return loadedConfig.tableVal[]

proc findConfigPath(): string =
  # TODO: find this path dynamically
  return "config.default.toml"

proc populateConfigTable*(display: PDisplay) =
  ## Reads the user's configuration file and set the keybindings.
  let configPath = findConfigPath()
  let configTable = loadConfigfile(configPath)
  display.populateAction("testAction", configTable)
  display.populateAction("testAction2", configTable)

