var path = require("path");

module.exports = {
  entry: './app/index.js',

  output: {
    path: path.resolve(__dirname + '/dist'),
    filename: 'index.js',
  },

  devServer: {
    contentBase: 'app',
    port: 8000,
    stats: { colors: true}
  },

  module: {
    rules: [
      {
        test:    /\.html$/,
        exclude: /node_modules/,
        loader:  'file-loader?name=index.[ext]'
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: 'elm-webpack-loader?verbose=true&warn=true'
      }
    ],

    noParse: /\.elm$/
  }
};
