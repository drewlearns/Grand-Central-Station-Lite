const path = require("path");
const nodeExternals = require("webpack-node-externals");
const CopyPlugin = require("copy-webpack-plugin");

module.exports = (env) => {
  return {
    mode: "production",
    entry: path.resolve(__dirname, "src", env.entry),
    target: "node", // Continue targeting Node.js
    output: {
      path: path.resolve(__dirname, "deploy"),
      filename: `${path.basename(env.entry, ".js")}.js`,
      libraryTarget: "commonjs2",
    },
    module: {
      rules: [
        {
          test: /\.m?js$/,
          exclude: /node_modules/,
          use: {
            loader: "babel-loader",
            options: {
              presets: ["@babel/preset-env"],
            },
          },
        },
      ],
    },
    plugins: [
      new CopyPlugin({
        patterns: [{ from: "prisma/schema.prisma", to: "schema.prisma" }],
      }),
    ],
    optimization: {
      minimize: false,
    },
    externals: [nodeExternals()], // Exclude all node_modules
    node: {
      __dirname: false,
      __filename: false,
      global: true,
    },
    resolve: {
      fallback: {
        "crypto": require.resolve("crypto"),
        "stream": require.resolve("stream"),
        "buffer": require.resolve("buffer"),
        "process": require.resolve("process"),
        "@smithy/config-resolver": require.resolve("@smithy/config-resolver"),
        "@smithy/util-endpoints": require.resolve("@smithy/util-endpoints"),
      }
    },
  };
};
