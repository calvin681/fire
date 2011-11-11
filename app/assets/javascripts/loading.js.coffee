$ = jQuery

$ () ->
  loading = $("div.users-show p.importing")
  return if loading.length is 0
  
  timeout = 1000
  finishCheck = () ->
    $.get loading.attr("data-check-url"), (data) ->
      if data.importing
        timeout = Math.min((if timeout <= 5000 then timeout + 1000 else timeout * 2), 60000)
        setTimeout finishCheck, timeout
      else
        window.location.reload()
        
  finishCheck()