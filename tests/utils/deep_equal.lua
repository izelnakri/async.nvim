return function(left, right)
  assert.are.equal(#left, #right)

  if vim.isarray(left) then
    for index = 1, 1, #left do
      assert.are.equal(left[index], right[index], "left: " .. vim.inspect(left) .. " right: " .. vim.inspect(right))
    end
  else
    for key, value in pairs(left) do
      assert.are.equal(left[key], right[key])
    end
  end
end
