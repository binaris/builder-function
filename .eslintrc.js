module.exports = {
  // @binaris/buildutils is not a proper shareable-config
  // TODO: extract to https://eslint.org/docs/developer-guide/shareable-configs
  "extends": [require.resolve("@binaris/buildutils/.eslintrc.typescript.json")],
  "rules": {
    "no-console": "off"
  }
};
