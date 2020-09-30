module JSONRequests
  def post_json(path, body = nil)
    header('Content-Type', 'application/json')
    post(path, body && JSON.generate(body))
  end

  def patch_json(path, body = nil)
    header('Content-Type', 'application/json')
    patch(path, body && JSON.generate(body))
  end
end
