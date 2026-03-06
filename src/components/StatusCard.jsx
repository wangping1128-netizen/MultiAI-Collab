const REACT_ELEMENT_TYPE = Symbol.for('react.element');

function createElement(type, props, ...children) {
  const nextProps = { ...(props || {}) };

  if (children.length === 1) {
    nextProps.children = children[0];
  } else if (children.length > 1) {
    nextProps.children = children;
  }

  return {
    $$typeof: REACT_ELEMENT_TYPE,
    type,
    key: null,
    ref: null,
    props: nextProps,
    _owner: null,
  };
}

function formatTimestamp(timestamp) {
  const parsedDate = new Date(timestamp);

  if (Number.isNaN(parsedDate.getTime())) {
    return 'Invalid timestamp';
  }

  return parsedDate.toLocaleString();
}

function StatusCard({ title, status, timestamp }) {
  const statusColor = status === 'ok' ? 'green' : 'red';
  const formattedTimestamp = formatTimestamp(timestamp);

  return createElement(
    'div',
    {
      className: 'status-card',
      style: {
        border: `1px solid ${statusColor}`,
        borderRadius: '8px',
        padding: '16px',
        margin: '8px',
        width: '300px',
        backgroundColor: '#f9f9f9',
      },
    },
    createElement(
      'h3',
      {
        style: {
          margin: '0 0 10px 0',
          color: '#333',
        },
      },
      title
    ),
    createElement(
      'div',
      {
        style: {
          display: 'flex',
          alignItems: 'center',
          marginBottom: '10px',
        },
      },
      createElement('span', {
        style: {
          width: '12px',
          height: '12px',
          borderRadius: '50%',
          backgroundColor: statusColor,
          marginRight: '8px',
        },
      }),
      createElement(
        'span',
        {
          style: {
            color: statusColor,
            fontWeight: 'bold',
          },
        },
        status.toUpperCase()
      )
    ),
    createElement(
      'p',
      {
        style: {
          margin: '0',
          fontSize: '0.9em',
          color: '#666',
        },
      },
      'Last updated: ',
      formattedTimestamp
    )
  );
}

module.exports = StatusCard;
module.exports.default = StatusCard;
