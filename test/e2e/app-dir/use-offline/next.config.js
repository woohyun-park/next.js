/**
 * @type {import('next').NextConfig}
 */
const nextConfig = {
  cacheComponents: true,
  experimental: {
    // Keyed on the variant shard (see scripts/run-jest.sh) so the suite
    // covers both states. Enabled by default — a plain run exercises the
    // feature with no special env — and disabled in the variant run, where
    // the `@gate useOffline` tests assert the feature is inert.
    useOffline: process.env.__NEXT_TEST_VARIANT !== 'true',
    varyParams: true,
    optimisticRouting: true,
    cachedNavigations: true,
  },
}

module.exports = nextConfig
