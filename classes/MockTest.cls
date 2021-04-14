@isTest
global class MockTest implements HttpCalloutMock
{
    global httpResponse respond(HTTPrequest req)
    {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        //res.setBody('"'+jobInfo[0].Id+'"');
        //res.setStatus('Method Not Allowed');
        return res;
    }
}