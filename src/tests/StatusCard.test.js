const test = require('node:test');
const assert = require('node:assert/strict');
const StatusCard = require('../components/StatusCard.jsx');

function asArray(value) {
  if (typeof value === 'undefined') {
    return [];
  }

  return Array.isArray(value) ? value : [value];
}

test('StatusCard returns expected structure for ok status', () => {
  const props = {
    title: 'Validation Pipeline',
    status: 'ok',
    timestamp: '2026-03-06T12:30:00.000Z',
  };

  const card = StatusCard(props);
  const cardChildren = asArray(card.props.children);
  const formattedTimestamp = new Date(props.timestamp).toLocaleString();

  assert.equal(card.type, 'div');
  assert.equal(card.props.className, 'status-card');
  assert.equal(card.props.style.border, '1px solid green');
  assert.equal(cardChildren.length, 3);

  const titleNode = cardChildren[0];
  assert.equal(titleNode.type, 'h3');
  assert.equal(titleNode.props.children, props.title);

  const statusRow = cardChildren[1];
  const statusChildren = asArray(statusRow.props.children);
  assert.equal(statusRow.type, 'div');
  assert.equal(statusChildren[0].props.style.backgroundColor, 'green');
  assert.equal(statusChildren[1].props.children, 'OK');

  const timestampNode = cardChildren[2];
  assert.equal(timestampNode.type, 'p');
  assert.deepEqual(timestampNode.props.children, ['Last updated: ', formattedTimestamp]);
});

test('StatusCard uses red indicator for error status', () => {
  const card = StatusCard({
    title: 'Validation Pipeline',
    status: 'error',
    timestamp: '2026-03-06T12:30:00.000Z',
  });

  const statusRow = asArray(card.props.children)[1];
  const statusChildren = asArray(statusRow.props.children);

  assert.equal(card.props.style.border, '1px solid red');
  assert.equal(statusChildren[0].props.style.backgroundColor, 'red');
  assert.equal(statusChildren[1].props.children, 'ERROR');
});
