local settings = {
    apiKey = get("KAVENEGAR_API_KEY") and get("KAVENEGAR_API_KEY"):match("^%s*(.-)%s*$") or nil,
    insecure = get("KAVENEGAR_INSECURE") or false,
}

KavenegarApi = {
    API_URL = "%s://api.kavenegar.com/v1/%s/%s/%s.json/",
    VERSION = "1.2.2",

    get_path = function(self, method, base)
        base = base or "sms"
        local protocol = settings.insecure and "http" or "https"
        return string.format(self.API_URL, protocol, settings.apiKey, base, method)
    end,

    execute = function(self, url, data, callbackEvent, baseElement, callbackEventArgs)
        if type(settings.apiKey) ~= "string" or settings.apiKey == "" or settings.apiKey == "YOUR_API_TOKEN" then
            error("API key is missing or invalid. Please set a valid API key inside `meta.xml` before sending requests (KAVENEGAR_API_KEY).")
        end

        local headers = {
            Accept = "application/json",
            ["Content-Type"] = "application/x-www-form-urlencoded",
            charset = "utf-8"
        }

        local options = {
            headers = headers,
            method = "POST"
        }

        if data then
            options.postData = self:table_to_query(data)
        end

        fetchRemote(url, options, function(responseData, responseInfo)
            local json_response = nil
            local success, errMsg

            if responseInfo.success then
                json_response = fromJSON(responseData)

                if json_response["return"].status ~= 200 then
                    success = false
                    errMsg = string.format("API Error: %s (status: %d)", json_response["return"].message, json_response["return"].status)
                else
                    success = true
                end
            else
                success = false
                errMsg = string.format("HTTP Error: %s (status code: %d)", responseInfo.statusCode, responseInfo.statusCode)
            end

            if callbackEvent and baseElement then
                triggerEvent(callbackEvent, baseElement, success, responseInfo.statusCode, json_response, callbackEventArgs)
            end

            if not success then
                error(errMsg)
            end
        end)
    end,

    table_to_query = function(self, tbl)
        local query = {}
        for k, v in pairs(tbl) do
            table.insert(query, string.format("%s=%s", k, v))
        end
        return table.concat(query, "&")
    end,

    Send = function(self, sender, receptor, message, date, theType, localid, callbackEvent, baseElement, callbackEventArgs)
        if type(receptor) == "table" then
            receptor = table.concat(receptor, ",")
        end
        if type(localid) == "table" then
            localid = table.concat(localid, ",")
        end

        local path = self:get_path("send")
        local params = {
            receptor = receptor,
            sender = sender,
            message = message,
            date = date,
            type = theType,
            localid = localid
        }

        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    SendArray = function(self, sender, receptor, message, date, theType, localmessageid, callbackEvent, baseElement, callbackEventArgs)
        if not type(receptor) == "table" then
            receptor = {receptor}
        end
        if not type(sender) == "table" then
            sender = {sender}
        end
        if not type(message) == "table" then
            message = {message}
        end

        local repeatCount = #receptor
        if theType and not type(theType) == "table" then
            theType = {theType}
            for i = #theType + 1, repeatCount do
                theType[i] = theType[1]
            end
        end
        if localmessageid and not type(localmessageid) == "table" then
            localmessageid = {localmessageid}
            for i = #localmessageid + 1, repeatCount do
                localmessageid[i] = localmessageid[1]
            end
        end

        local path = self:get_path("sendarray")
        local params = {
            receptor = toJSON(receptor),
            sender = toJSON(sender),
            message = toJSON(message),
            date = date,
            type = toJSON(theType),
            localmessageid = toJSON(localmessageid)
        }

        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    Status = function(self, messageid, callbackEvent, baseElement, callbackEventArgs)
        local path = self:get_path("status")
        local params = {
            messageid = type(messageid) == "table" and table.concat(messageid, ",") or messageid
        }
        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    StatusLocalMessageId = function(self, localid, callbackEvent, baseElement, callbackEventArgs)
        local path = self:get_path("statuslocalmessageid")
        local params = {
            localid = type(localid) == "table" and table.concat(localid, ",") or localid
        }
        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    Select = function(self, messageid, callbackEvent, baseElement, callbackEventArgs)
        local params = {
            messageid = type(messageid) == "table" and table.concat(messageid, ",") or messageid
        }
        local path = self:get_path("select")
        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    SelectOutbox = function(self, startdate, enddate, sender, callbackEvent, baseElement, callbackEventArgs)
        local path = self:get_path("selectoutbox")
        local params = {
            startdate = startdate,
            enddate = enddate,
            sender = sender
        }
        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    LatestOutbox = function(self, pagesize, sender, callbackEvent, baseElement, callbackEventArgs)
        local path = self:get_path("latestoutbox")
        local params = {
            pagesize = pagesize,
            sender = sender
        }
        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    CountOutbox = function(self, startdate, enddate, status, callbackEvent, baseElement, callbackEventArgs)
        local path = self:get_path("countoutbox")
        local params = {
            startdate = startdate,
            enddate = enddate,
            status = status or 0
        }
        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    Cancel = function(self, messageid, callbackEvent, baseElement, callbackEventArgs)
        local path = self:get_path("cancel")
        local params = {
            messageid = type(messageid) == "table" and table.concat(messageid, ",") or messageid
        }
        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    Receive = function(self, linenumber, isread, callbackEvent, baseElement, callbackEventArgs)
        local path = self:get_path("receive")
        local params = {
            linenumber = linenumber,
            isread = isread or 0
        }
        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    CountInbox = function(self, startdate, enddate, linenumber, isread, callbackEvent, baseElement, callbackEventArgs)
        local path = self:get_path("countinbox")
        local params = {
            startdate = startdate,
            enddate = enddate,
            linenumber = linenumber,
            isread = isread or 0
        }
        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    CountPostalcode = function(self, postalcode, callbackEvent, baseElement, callbackEventArgs)
        local path = self:get_path("countpostalcode")
        local params = {
            postalcode = postalcode
        }
        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    SendbyPostalcode = function(self, sender, postalcode, message, mcistartindex, mcicount, mtnstartindex, mtncount, date, callbackEvent, baseElement, callbackEventArgs)
        local path = self:get_path("sendbypostalcode")
        local params = {
            postalcode = postalcode,
            sender = sender,
            message = message,
            mcistartindex = mcistartindex,
            mcicount = mcicount,
            mtnstartindex = mtnstartindex,
            mtncount = mtncount,
            date = date
        }
        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    AccountInfo = function(self, callbackEvent, baseElement, callbackEventArgs)
        local path = self:get_path("info", "account")
        return self:execute(path, nil, callbackEvent, baseElement, callbackEventArgs)
    end,

    AccountConfig = function(self, apilogs, dailyreport, debug, defaultsender, mincreditalarm, resendfailed, callbackEvent, baseElement, callbackEventArgs)
        local path = self:get_path("config", "account")
        local params = {
            apilogs = apilogs,
            dailyreport = dailyreport,
            debug = debug,
            defaultsender = defaultsender,
            mincreditalarm = mincreditalarm,
            resendfailed = resendfailed
        }
        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    VerifyLookup = function(self, receptor, token, token2, token3, template, theType, token10, token20, callbackEvent, baseElement, callbackEventArgs)
        local path = self:get_path("lookup", "verify")
        local params = {
            receptor = receptor,
            token = token,
            token2 = token2,
            token3 = token3,
            template = template,
            type = theType,
            token10 = token10,
            token20 = token20,
        }
        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,

    CallMakeTTS = function(self, receptor, message, date, localid, callbackEvent, baseElement, callbackEventArgs)
        local path = self:get_path("maketts", "call")
        local params = {
            receptor = receptor,
            message = message,
            date = date,
            localid = localid
        }
        return self:execute(path, params, callbackEvent, baseElement, callbackEventArgs)
    end,
}

addEventHandler("onResourceStart", resourceRoot, function()
    if type(settings.apiKey) ~= "string" or settings.apiKey == "" or settings.apiKey == "YOUR_API_TOKEN" then
            error("API key is missing or invalid. Please set a valid API key inside `meta.xml` (KAVENEGAR_API_KEY).")
    end
end)