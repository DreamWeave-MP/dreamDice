#include <lauxlib.h>
#include <lua.h>

#include "main.h"
#include "roll.h"
#include "test_rolls.h"

const char *BUFFER_LOAD_FAILED_STR = "Failed to load %s: %s";
const char *BUFFER_EXEC_FAILED_STR = "Failed to execute %s: %s";

int loadBufferToGlobal(lua_State *L, const char *name,
                       const unsigned char *buffer, size_t bufferSize) {
  if (luaL_loadbuffer(L, (const char *)buffer, bufferSize, name) != LUA_OK ||
      lua_pcall(L, 0, 1, 0) != LUA_OK) {
    return luaL_error(L, BUFFER_LOAD_FAILED_STR, name, lua_tostring(L, -1));
  }

  lua_setglobal(L, name);
  return 1;
}

int loadAndExecuteBuffer(lua_State *L, const char *name,
                         const unsigned char *buffer, size_t bufferSize) {
  // Load the buffer
  if (luaL_loadbuffer(L, (const char *)buffer, bufferSize, name) != LUA_OK) {
    return luaL_error(L, BUFFER_LOAD_FAILED_STR, name, lua_tostring(L, -1));
  }

  // Execute the loaded chunk
  if (lua_pcall(L, 0, LUA_MULTRET, 0) != LUA_OK) {
    return luaL_error(L, BUFFER_EXEC_FAILED_STR, name, lua_tostring(L, -1));
  }

  // The number of results is now on top of the stack
  return lua_gettop(L);
}

int luaopen_dreamDice(lua_State *L) {

  int moduleLoaded =
      loadBufferToGlobal(L, "Roll", luaJIT_BC_roll, luaJIT_BC_roll_SIZE);
  if (moduleLoaded != 1)
    return moduleLoaded;

  moduleLoaded = loadBufferToGlobal(L, "RollTests", luaJIT_BC_test_rolls,
                                    luaJIT_BC_test_rolls_SIZE);
  if (moduleLoaded != 1)
    return moduleLoaded;

  loadAndExecuteBuffer(L, "rollmain", luaJIT_BC_main, luaJIT_BC_main_SIZE);

  return 1;
}
