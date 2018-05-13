function displayFlashVideo(target, script, state)
{
  if (target.parentNode && target.parentNode.innerHTML)
  {
    if (state) {
      target.parentNode.innerHTML = "[<a href=\"#\" onclick=\"return displayFlashVideo(this, unescape('" + escape(script) + "'), " + !state + ");\">Hide Video</a>]<br/>" + script;
    } else {
      target.parentNode.innerHTML = "[<a href=\"#\" onclick=\"return displayFlashVideo(this, unescape('" + escape(script) + "'), " + !state + ");\">View Video</a>]";
    }
    return false;
  }
  return true;
}
