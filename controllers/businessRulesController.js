const proxyHandler = {
  get(target, prop) {
    if (typeof prop === 'string' && !(prop in target)) {
      return async (req, res) => res.status(200).json({ message: `Stub for ${prop}` });
    }
    return target[prop];
  }
};

module.exports = new Proxy({}, proxyHandler);