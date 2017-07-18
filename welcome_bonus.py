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
            proxy.sendtoaddress(address, 100000)
            return 'sent'
        else:
            return 'invalid address'


site = server.Site(MyResource())

reactor.listenTCP(8000, site)
reactor.run()
