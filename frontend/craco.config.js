module.exports = {
  webpack: {
    configure: (webpackConfig) => {
      // Fix for @react-native-async-storage module resolution in web builds
      webpackConfig.resolve = {
        ...webpackConfig.resolve,
        fallback: {
          ...webpackConfig.resolve.fallback,
          crypto: false,
          stream: false,
          http: false,
          https: false,
          zlib: false,
        },
        alias: {
          ...webpackConfig.resolve.alias,
          // Mock @react-native-async-storage for web
          '@react-native-async-storage/async-storage': false,
        },
        fullySpecified: false, // Disable the need for .js extension in imports
      };

      // Ignore source map warnings from node_modules
      webpackConfig.ignoreWarnings = [/Failed to parse source map/];

      return webpackConfig;
    },
  },
};
