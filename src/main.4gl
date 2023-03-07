IMPORT os
IMPORT util
IMPORT com
IMPORT FGL fgldialog

-- This URL is my demo server - Change this to point to your server.
CONSTANT C_URL  = "https://generodemos.dynu.net/g/ws/r/si/storeImage"
CONSTANT C_TIMEOUT = 10

DEFINE m_dir STRING = "."
DEFINE m_err STRING
DEFINE m_text STRING
DEFINE m_logFile STRING
MAIN
	DEFINE l_uri STRING
	DEFINE l_dir STRING

	LET m_logFile = base.Application.getProgramName() || ".txt"

	IF base.Application.isMobile() THEN
-- NOTE: The location of the log file on the device might need to be somewhere different
-- you could also just have the log save in the running folder since the app can send the
-- log to the server.
		LET l_dir = "/storage/emulated/0/download"
		LET m_logFile = os.Path.join(l_dir, m_logFile)
	END IF

	OPEN FORM f FROM "form"
	DISPLAY FORM f

	DISPLAY SFMT("%1 %2 Mobile: %3\nLog: %4",
					ui.Interface.getFrontEndName(), ui.Interface.getFrontEndVersion(),
					base.Application.isMobile(), m_logFile)
			TO info

	MENU
		ON ACTION takePhoto
			CALL ui.Interface.frontCall("mobile", "takePhoto", [], [l_uri])
			IF l_uri IS NOT NULL THEN
				IF NOT sendFile(l_uri, "saveImg", "image/jpeg", TRUE) THEN
					CALL fgl_winMessage("Failed", m_err, "exclamation")
				ELSE
					CALL fgl_winMessage("Okay", m_err, "information")
				END IF
			END IF
			DISPLAY BY NAME m_text

		ON ACTION choosePhoto
			CALL ui.Interface.frontCall("mobile", "choosePhoto", [], [l_uri])
			IF l_uri IS NOT NULL THEN
				IF NOT sendFile(l_uri, "saveImg", "image/jpeg", TRUE) THEN
					CALL fgl_winMessage("Failed", m_err, "exclamation")
				ELSE
					CALL fgl_winMessage("Okay", m_err, "information")
				END IF
			END IF
			DISPLAY BY NAME m_text

		ON ACTION test
			IF NOT sendFile("test.jpg", "saveImg", "image/jpeg", FALSE) THEN
				CALL fgl_winMessage("Failed", m_err, "exclamation")
			ELSE
				CALL fgl_winMessage("Okay", m_err, "information")
			END IF
			DISPLAY BY NAME m_text

-- Send the client application's log to the server
		ON ACTION sendlog
			IF NOT sendFile(m_logFile, "saveLog", "text/plain", FALSE) THEN
				CALL fgl_winMessage("Failed", m_err, "exclamation")
			ELSE
				CALL fgl_winMessage("Okay", m_err, "information")
			END IF
			DISPLAY BY NAME m_text

-- A test for timeouts from the client
		ON ACTION timeout
			IF NOT timeoutTest(10) THEN
			END IF
			DISPLAY BY NAME m_text

		ON ACTION quit
			EXIT MENU
	END MENU

END MAIN
--------------------------------------------------------------------------------------------------------------
-- Send a file to the server
-- @param l_uri : File URI - can be image or file or uri to a google/android image
-- @param l_service : Name of the server on the server to use.
-- @param l_type : mime type of file to send
-- @param l_isUri : Boolean TRUE = google/android image, FALSE = normal file
FUNCTION sendFile(l_uri STRING, l_service STRING, l_type STRING, l_isUri BOOLEAN) RETURNS BOOLEAN
	DEFINE
		l_req com.HttpRequest,
		l_resp com.HttpResponse,
		l_reply STRING,
		l_newFile STRING,
		l_url STRING

-- If it's a URI we need to get it to the local folder a 'normal' file.
	IF l_isUri THEN
		LET l_newFile =
				SFMT("img%1.jpg", util.Datetime.format(CURRENT, "%Y%m%d_%H%M%S"))
		LET l_newFile = os.Path.join(m_dir, l_newFile)
		TRY
			CALL fgl_getfile( l_uri, l_newFile )
		--IF NOT os.Path.copy(l_uri, l_newFile) THEN
		CATCH
			LET m_err = SFMT("Failed to copy file '%1' to %2", l_uri, l_newFile)
			CALL logIt(__LINE__, m_err)
			RETURN FALSE
		END TRY
	ELSE
		LET l_newFile = l_uri
	END IF

-- Check we actually have a 'normal' file.
	IF NOT os.Path.exists(l_newFile) THEN
		LET m_err = SFMT("SendFile: %1 Not found!", l_newFile)
		CALL logIt(__LINE__, m_err)
		RETURN FALSE
	END IF

-- build the url
	LET l_url = SFMT("%1/%2", C_URL, l_service)
	CALL logIt(__LINE__, SFMT("SendFile: %1 to %2", l_newFile, l_url))
	TRY -- POST to the file to the server
		LET l_req = com.HttpRequest.Create(l_url)
		CALL l_req.setMethod("POST")
		CALL l_req.setHeader("accept", "application/json")
		CALL l_req.setHeader("content-type", l_type)
		CALL l_req.setHeader("X-fileName", l_newFile)
		IF l_type MATCHES ("image/*") THEN
			CALL l_req.setHeader("X-type", "image")
		ELSE
			CALL l_req.setHeader("X-type", "text")
		END IF
		CALL l_req.setConnectionTimeOut(C_TIMEOUT)
		CALL l_req.setTimeOut(C_TIMEOUT)
		CALL l_req.doFileRequest(l_newFile)
		LET l_resp = l_req.getResponse()
		IF l_resp.getStatusCode() != 200 THEN
			LET m_err =
					SFMT("SendFile: Error %1 %2",
							l_resp.getStatusCode(), l_resp.getStatusDescription())
			CALL logIt(__LINE__, m_err)
			RETURN FALSE
		ELSE
			LET l_reply = l_resp.getTextResponse()
		END IF
	CATCH
		LET m_err = SFMT("SendFile: Failed %1 %2", status, sqlca.sqlerrm)
		CALL logIt(__LINE__, m_err)
		RETURN FALSE
	END TRY
	LET m_err = SFMT("SendFile: %1", l_reply)
	CALL logIt(__LINE__, m_err)
	RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------------------------------------
-- For testing timeouts on the server.
FUNCTION timeoutTest(l_tim INT)
	DEFINE
		l_req com.HttpRequest,
		l_resp com.HttpResponse,
		l_reply STRING,
		l_url STRING

	LET l_url = SFMT("%1/pause/%2", C_URL, l_tim)
	CALL logIt(__LINE__, SFMT("timeoutTest: %1 to %2", l_tim, l_url))

	TRY
		LET l_req = com.HttpRequest.Create(l_url)
		CALL l_req.setMethod("GET")
		CALL l_req.setHeader("accept", "application/json")
		CALL l_req.setConnectionTimeOut(C_TIMEOUT)
		CALL l_req.setTimeOut(C_TIMEOUT)
		CALL l_req.doRequest()
		LET l_resp = l_req.getResponse()
		IF l_resp.getStatusCode() != 200 THEN
			CALL logIt(
					__LINE__,
					SFMT("timeoutTest: Error %1 %2",
							l_resp.getStatusCode(), l_resp.getStatusDescription()))
			RETURN FALSE
		ELSE
			LET l_reply = l_resp.getTextResponse()
		END IF
	CATCH
		CALL logIt(
				__LINE__, SFMT("timeoutTest: Failed %1 %2", status, sqlca.sqlerrm))
		RETURN FALSE
	END TRY
	CALL logIt(__LINE__, SFMT("timeoutTest: Done - Reply %1", l_reply))
	RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------------------------------------
FUNCTION logIt(l_line INT, l_msg STRING)
	DEFINE c base.Channel

	LET m_text = m_text.append(SFMT("%1\n", l_msg))
	LET c = base.Channel.create()
	CALL c.openFile(m_logFile, "a+")
	LET l_msg =
			SFMT("%1:%2:%3",
					util.Datetime.format(CURRENT, "%Y%m%d_%H%M%S"), l_line, l_msg)
	DISPLAY SFMT("LOG: %1", l_msg)
	CALL c.writeLine(l_msg)
	CALL c.close()
END FUNCTION
