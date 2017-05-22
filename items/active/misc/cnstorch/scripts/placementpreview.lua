function update()
  localAnimator.clearDrawables()
  local isInPlaceMode = animationConfig.animationParameter("isInPlaceMode", false)
  if isInPlaceMode then
    local previewPosition = animationConfig.animationParameter("previewPosition")

    if previewPosition then
      local previewImage = animationConfig.animationParameter("previewImage")
      if previewImage == nil then
        return
      end
      local previewValid = animationConfig.animationParameter("previewValid")

      if previewValid then
        previewImage = previewImage .. ":default.default?fade=55FF5500;0.25?border=2;66FF6677;00000000"
      else
        previewImage = previewImage .. ":default.default?fade=FF555500;0.25?border=2;FF666677;00000000"
      end

      localAnimator.addDrawable({
        image = previewImage,
        position = previewPosition,
        fullbright = true
      })
    end
  end
end
