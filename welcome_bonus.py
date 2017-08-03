import bitcoin.rpc
from twisted.internet import reactor
from twisted.web import resource, server

class MyResource(resource.Resource):
    isLeaf = True

    def render_GET(self, request):
        proxy = bitcoin.rpc.Proxy()
        print(proxy.getinfo())
        print(request)
        address = request.postpath[0].decode('utf-8')
        print(address)
        isvalid = proxy._call('validateaddress', str(address))['isvalid']

        print(isvalid)
        if isvalid:
            try:
                decode = request.postpath[1].decode('utf-8')
                print(decode)
                value = int(decode)
            except:
                value = 100000

            proxy.sendtoaddress(address, value)
            return 'sent'
        else:
            return 'invalid address'


site = server.Site(MyResource())

reactor.listenTCP(8000, site)
reactor.run()
