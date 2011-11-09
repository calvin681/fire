$ = jQuery

$ () ->
  return if $("#fb-root").length is 0
  ((d, s, id) ->
    fjs = d.getElementsByTagName(s)[0]
    return if d.getElementById(id)
    js = d.createElement(s)
    js.id = id
    js.src = "//connect.facebook.net/en_US/all.js#xfbml=1&appId=271284029577374"
    fjs.parentNode.insertBefore(js, fjs)
  )(document, 'script', 'facebook-jssdk')
