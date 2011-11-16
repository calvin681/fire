po = document.createElement('script')
po.type = 'text/javascript'
po.async = true
po.src = 'https://apis.google.com/js/plusone.js'
s = document.getElementsByTagName('script')[0]
s.parentNode.insertBefore(po, s)


# Analytics
window._gaq = window._gaq or []
window._gaq.push(['_setAccount', 'UA-27036924-1'])
window._gaq.push(['_trackPageview'])

ga = document.createElement('script')
ga.type = 'text/javascript'
ga.async = true;
ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js'
s = document.getElementsByTagName('script')[0]
s.parentNode.insertBefore(ga, s)
