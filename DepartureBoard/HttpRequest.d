module HttpRequest;

import XmlParser;
import core.sys.windows.windows;
import core.sys.windows.wininet;

import std.exception;
import std.conv;
import std.stdio;
import std.string;

class HttpRequester
{
	HINTERNET _hNet = null;
	HINTERNET _hConnection = null;
	HINTERNET _hRequest = null;

	string _url;

	this(string url)
	{
		_url = url;
	}

	bool init()
	{
		if( _hRequest ) return true;

		_hNet = InternetOpenA("XYZ", INTERNET_OPEN_TYPE_DIRECT, NULL, NULL, 0);

		URL_COMPONENTSA comps;

		char[256] szHostName;
		char[256] szPath;

		comps.dwStructSize = comps.sizeof;
		comps.lpszHostName = szHostName.ptr;
		comps.dwHostNameLength = szHostName.length;
		comps.lpszUrlPath = szPath.ptr;
		comps.dwUrlPathLength = szPath.length;

		InternetCrackUrlA(_url.ptr, cast(DWORD) _url.length, 0, &comps);

		_hConnection = InternetConnectA(_hNet, comps.lpszHostName, comps.nPort,
												 null, null, INTERNET_SERVICE_HTTP, 0, cast(DWORD_PTR) null);

		_hRequest = HttpOpenRequestA(_hConnection,"POST",comps.lpszUrlPath,null,null,null,
											  INTERNET_FLAG_KEEP_CONNECTION | INTERNET_FLAG_SECURE, cast(DWORD_PTR) null);

		return cast(bool) _hRequest;
	}

	bool send(string header, string data)
	{
		if( !init() ) return false;

		auto b = HttpSendRequestA(_hRequest, header.ptr, cast(DWORD) header.length, cast(LPVOID)data.ptr, cast(DWORD) data.length);

		return cast(bool) b;
	}

	string response()
	{
		char[1024] szData;
		DWORD dwBytesRead=0;

		auto isRead = InternetReadFile(_hRequest, szData.ptr, szData.length - 1, &dwBytesRead);

		string strData = to!string(szData[0 .. dwBytesRead]);

		while (isRead && dwBytesRead > 0)
		{
			dwBytesRead = 0;
			isRead = InternetReadFile(_hRequest, szData.ptr, szData.length - 1, &dwBytesRead);
			strData ~= to!string(szData[0 .. dwBytesRead]);
		}
		
		return strData;
	}

	~this()
	{
		InternetCloseHandle(_hRequest);
		InternetCloseHandle(_hConnection);
		InternetCloseHandle(_hNet);
	}

}

bool execute(T)(HttpRequester requester,T request)
{
	if( requester.send(request.header(),request.data.format()) )
	{
		auto builder = new NodeBuilder;
		return request.processResponse(builder.buildNode(requester.response));
	}

	return false;
}


