const fs = require('node:fs')
const path = require('node:path')
const vm = require('node:vm')
const test = require('node:test')
const assert = require('node:assert/strict')

const source = fs.readFileSync(path.join(__dirname, '..', 'Model.js'), 'utf8')
  .replace(/^\.pragma library\s*/m, '')
const context = { Date, Math, Number, String, Array, isFinite }
vm.createContext(context)
vm.runInContext(source, context)

test('formats compact public metrics', () => {
  assert.equal(context.compactNumber(999), '999')
  assert.equal(context.compactNumber(1250), '1.3K')
  assert.equal(context.compactNumber(2000000), '2M')
})

test('formats relative activity time', () => {
  const now = Date.parse('2026-03-18T12:00:00Z')
  assert.equal(context.relativeTime('2026-03-18T11:59:40Z', now), 'just now')
  assert.equal(context.relativeTime('2026-03-18T11:20:00Z', now), '40m ago')
  assert.equal(context.relativeTime('2026-03-18T09:00:00Z', now), '3h ago')
})

test('filters posts and replies without mutating input', () => {
  const posts = [{ kind: 'post' }, { kind: 'reply' }, { kind: 'quote' }]
  assert.equal(context.filteredPosts(posts, 'posts').length, 2)
  assert.equal(context.filteredPosts(posts, 'replies').length, 1)
  assert.equal(posts.length, 3)
})

test('maps activity to animation levels', () => {
  assert.equal(context.activityLevel(0), 0)
  assert.equal(context.activityLevel(1), 1)
  assert.equal(context.activityLevel(8), 2)
  assert.equal(context.activityLevel(24), 3)
})
