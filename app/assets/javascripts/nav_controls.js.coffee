$ = jQuery

$ () ->
  $("div.users-show div.nav form.privacy").bind "ajax:success", (event, data) ->
    $form = $(@)
    add = "private"
    remove = "public"
    [add, remove] = [remove, add] if data.public
    $form.removeClass(remove).addClass(add)
    $share = $(".nav .social-networks")
    $share.removeClass(remove).addClass(add)
