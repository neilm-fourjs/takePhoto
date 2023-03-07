-- This module contains the functions for the REST service.
-- The functions:
-- saveImg: For saving a image that is POST'd from the client side.
-- saveLog: For saving a file, specifically for this demo a 'log' file from the client.
-- pause: A testing function for testing timeouts in the client code.
IMPORT os
IMPORT util
PUBLIC DEFINE serviceInfo
		RECORD ATTRIBUTES(WSInfo) --, WSVersion = "v2", WSVersionMode = "uri")
	title STRING,
	description STRING,
	termOfService STRING,
	contact RECORD
		name STRING,
		url STRING,
		email STRING
	END RECORD,
	version STRING
END RECORD =
		(title: "storeImage", version: "1.2", contact:(email: "neilm@4js.com"))

-- These file paths will be relative to the deployment folder.
DEFINE m_dir STRING = "../images"
DEFINE m_dir2 STRING = "../files"
--------------------------------------------------------------------------------------------------------------
-- Save an image to a folder
FUNCTION saveImg(
		l_data STRING ATTRIBUTE(WSAttachment, WSMedia = "image/*"),
		l_file STRING ATTRIBUTES(WSHeader, WSOptional, WSName = "X-fileName",
				WSDescription = "File name"))
		ATTRIBUTES(WSPost, WSPath = "/saveImg", WSDescription = "Store an image file")
		RETURNS STRING ATTRIBUTES(WSMedia = 'application/json')
	DEFINE l_msg STRING

	CALL logIt(__LINE__, SFMT("File: %1", l_file))

-- Look to see if the server save folder exists and create it if it's missing.
	IF NOT os.Path.exists(m_dir) THEN
		IF NOT os.Path.mkdir(m_dir) THEN
			LET l_msg = SFMT("save: Failed to create %1", m_dir)
			CALL logIt(__LINE__, l_msg)
			RETURN l_msg
		END IF
	END IF

-- Check we actually got a file.
	IF NOT os.Path.exists(l_data) THEN
		LET l_msg = SFMT("save: File %1 doesn't exist!", l_data)
		CALL logIt(__LINE__, l_msg)
		RETURN l_msg
	END IF

-- I could use l_file as it's passed correctly but I'm going to generate a new name that's unique instead.
	LET l_file = SFMT("img%1.jpg", util.Datetime.format(CURRENT, "%Y%m%d_%H%M%S"))
	LET l_file = os.Path.join(m_dir, l_file)

-- Copy the file from temp location to where we want to save it.
	IF NOT os.Path.copy(l_data, l_file) THEN
		LET l_msg = SFMT("save: Failed to rename %1 to %2", l_data, l_file)
		CALL logIt(__LINE__, l_msg)
		RETURN l_msg
	END IF

	RETURN SFMT("File %1 Saved.", l_file)
END FUNCTION
--------------------------------------------------------------------------------------------------------------
-- Save a to a folder
-- NOTE: l_type is currently not used by could be used to store the file in a 
--       different folder based on it's type.
FUNCTION saveLog(
		l_data STRING ATTRIBUTE(WSAttachment, WSMedia = "text/plain"),
		l_file STRING ATTRIBUTES(WSHeader, WSOptional, WSName = "X-fileName",
				WSDescription = "File name"),
		l_type STRING ATTRIBUTES(WSHeader, WSOptional, WSName = "X-type",
				WSDescription = "File type"))
		ATTRIBUTES(WSPost, WSPath = "/saveLog", WSDescription = "Store a file")
		RETURNS STRING ATTRIBUTES(WSMedia = 'application/json')
	DEFINE l_msg STRING

	CALL logIt(__LINE__, SFMT("File: %1", l_file))

-- Look to see if the server save folder exists and create it if it's missing.
	IF NOT os.Path.exists(m_dir2) THEN
		IF NOT os.Path.mkdir(m_dir2) THEN
			LET l_msg = SFMT("saveLog: Failed to create %1", m_dir2)
			CALL logIt(__LINE__, l_msg)
			RETURN l_msg
		END IF
	END IF

-- Check we actually got a file.
	IF NOT os.Path.exists(l_data) THEN
		LET l_msg = SFMT("saveLog: File %1 doesn't exist!", l_data)
		CALL logIt(__LINE__, l_msg)
		RETURN l_msg
	END IF

-- append a datetime stamp to the file name.
	LET l_file = SFMT("%1.%3", os.Path.baseName(l_file),util.Datetime.format(CURRENT, "%Y%m%d_%H%M%S"))
	LET l_file = os.Path.join(m_dir2, l_file)

-- Copy the file from temp location to where we want to save it.
	IF NOT os.Path.copy(l_data, l_file) THEN
		LET l_msg = SFMT("saveLog: Failed to rename %1 to %2", l_data, l_file)
		CALL logIt(__LINE__, l_msg)
		RETURN l_msg
	END IF

	RETURN SFMT("File %1 Saved.", l_file)
END FUNCTION
--------------------------------------------------------------------------------------------------------------
-- Test service for testing timeouts.
FUNCTION pause(l_tim INTEGER ATTRIBUTE(WSParam))
		ATTRIBUTES(WSGet, WSPath = "/pause/{l_tim}",
				WSDescription = "Pause for timeout test")
		RETURNS STRING ATTRIBUTES(WSMedia = 'application/json')
	CALL logIt(__LINE__, SFMT("pause: Time: %1", l_tim))
	SLEEP l_tim
	RETURN SFMT("Paused for %1 seconds", l_tim)
END FUNCTION
--------------------------------------------------------------------------------------------------------------
-- Simple logging function.
FUNCTION logIt(l_line INT, l_msg STRING)
	DEFINE c base.Channel
	DEFINE l_logFile STRING
	LET l_logFile = base.Application.getProgramName() || ".log"
	LET c = base.Channel.create()
	CALL c.openFile(l_logFile, "a+")
	LET l_msg =
			SFMT("%1:%2:%3",
					util.Datetime.format(CURRENT, "%Y%m%d_%H%M%S"), l_line, l_msg)
	DISPLAY SFMT("LOG: %1", l_msg)
	CALL c.writeLine(l_msg)
	CALL c.close()
END FUNCTION
