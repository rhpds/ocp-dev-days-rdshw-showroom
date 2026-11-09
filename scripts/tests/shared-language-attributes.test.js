const test = require('node:test')
const assert = require('node:assert/strict')
const extension = require('../../extensions/shared-language-attributes')

function run(components) {
  extension.register.call({
    once(event, callback) {
      assert.equal(event, 'contentClassified')
      callback({ contentCatalog: { getComponents: () => components } })
    },
  })
}

test('runtime credentials and URLs reach every language without replacing its locale', () => {
  const english = { version: 'en', asciidoc: { attributes: {
    user: 'sample-user', password: 'sample-password',
    openshift_cluster_ingress_domain: 'sample.example', 'page-lang': 'en',
  } } }
  const languages = ['ja', 'es', 'it'].map(version => ({
    version, asciidoc: { attributes: { 'page-lang': version, experimental: true } },
  }))
  const before = structuredClone(english)
  run([{ versions: [english, ...languages] }])
  for (const language of languages) {
    assert.equal(language.asciidoc.attributes.user, 'sample-user')
    assert.equal(language.asciidoc.attributes.password, 'sample-password')
    assert.equal(language.asciidoc.attributes.openshift_cluster_ingress_domain, 'sample.example')
    assert.equal(language.asciidoc.attributes['page-lang'], language.version)
  }
  assert.deepEqual(english, before)
})

test('explicit target attributes win and shared site configuration is not mutated', () => {
  const shared = { attributes: { user: 'site-user' } }
  const target = { version: 'ja', asciidoc: shared }
  run([{ versions: [
    { version: 'en', asciidoc: { attributes: { user: 'english-user', password: 'sample-password' } } },
    target,
  ] }])
  assert.equal(target.asciidoc.attributes.user, 'site-user')
  assert.equal(target.asciidoc.attributes.password, 'sample-password')
  assert.deepEqual(shared, { attributes: { user: 'site-user' } })
})

test('components without English and unrelated components remain isolated', () => {
  const unrelated = { versions: [{ version: 'ja', asciidoc: { attributes: { 'page-lang': 'ja' } } }] }
  const before = structuredClone(unrelated)
  run([{ versions: [{ version: 'en', asciidoc: { attributes: { password: 'sample-password' } } }] }, unrelated])
  assert.deepEqual(unrelated, before)
})
