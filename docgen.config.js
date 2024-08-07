// docgen.config.js

module.exports = {
    // The directory where your Solidity contracts are located
    input: './src', // Adjust this path to your contracts directory

    // The output directory for the generated documentation
    output: './docs', // Adjust this path to your desired output directory

    // Specify the Solidity version used in your contracts
    // This is optional, but can help with compatibility
    version: '0.8.0', // Change this to match your Solidity version

    // Include/exclude specific files or directories
    // Use glob patterns to match files
    include: [
        '**/*.sol', // Include all Solidity files
    ],
    exclude: [
        'test/**', // Exclude test files or directories
        'migrations/**', // Exclude migration files if using Truffle
    ],

    // Optional: Customize the template used for documentation
    template: {
        // You can specify a custom template if needed
        // default: 'default'
        name: 'default',
    },

    // Optional: Specify the output format
    format: 'markdown', // Can be 'html', 'markdown', etc.

    // Optional: Enable or disable certain features
    features: {
        // Enable or disable specific features
        // For example, you can enable or disable the generation of diagrams
        diagrams: true,
    },
};