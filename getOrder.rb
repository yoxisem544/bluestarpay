require 'digest/md5'
require 'rest_client'
require 'nokogiri'
require 'iconv'

# code 之後上線後會由藍星給我們
code = "abcd1234"
postUrl = "https://testmaple2.neweb.com.tw/CashSystemFrontEnd/Payment"

# 準備 post 給 藍星 的 data
postDate = {
	# 米斯克 商店編號
	:merchantnumber => "460172",
	# 訂單編號, 可能要另外產生一組, 防止資料盜取
	:ordernumber => "101029290141",
	# 金額
	:amount => "14000",
	# 付款方式 均為MMK, MMK為超商代碼付款
	:paymenttype => "MMK",
	:duedate => "20160215",
	# 付款者姓名, 沒有填就預設為FB姓名？
	:payname => "安安好",
	# 付款者手機號碼
	:payphone => "0987123123",
	# 是否回傳一段url? 0 => 他們產生網頁給我們, 1 => 他們回傳一段url給我們解析
	:returnvalue => 1,
	# hash = md5(merchantnumber + code + amount + ordernumber)
	:hash => "",
	# 給產生的網頁轉跳的網址, 應該不會用到
	:nexturl => ""
}

# 準備 hash = md5(merchantnumber + code + amount + ordernumber)
postDate[:hash] = Digest::MD5.hexdigest(postDate[:merchantnumber] + code + postDate[:amount] + postDate[:ordernumber])

r = RestClient.post postUrl, postDate
ic = Iconv.new("utf-8//translit//IGNORE","UTF-8")
n = Nokogiri::HTML(ic.iconv(r.to_s))

# puts n

# 回傳資料
responseData = n.css('p').text.split('&')

# puts "回傳資料: ", responseData

# 處理回傳資料
begin
	amount = responseData[1].split('=').last
	merchantnumber = responseData[2].split('=').last
	ordernumber = responseData[3].split('=').last
	paycode = responseData[4].split('=').last
	checksum = responseData[5].split('=').last

	# 準備驗證資料
	responseDataInString = ""
	5.times do |i|
		responseDataInString += responseData[i] + "&"
	end

	# 驗證碼
	# checksum = md5(responsedata + "&code=" + code);
	checker = Digest::MD5.hexdigest(responseDataInString + "code=" + code)

	puts amount, merchantnumber, ordernumber, paycode, checksum
	puts "驗證結果: " + (checker == checksum ? "沒有被造假" : "資料被串改")
rescue
	puts "訂單重複！" if responseData[0].split('=').last == "70"
	puts "商店編號不存在！" if responseData[0].split('=').last == "27" 
	puts "上限金額高於兩萬！" if responseData[0].split('=').last == "33"
	puts "未指定支付工具不支援！" if responseData[0].split('=').last == "-8"
	puts "參數(繳款人姓名(payname))長度超過 100 或者 參數(繳款人電話(payphone))長度超過 20 或者 格式有誤 或者 hash 有誤！" if responseData[0].split('=').last == "-101"
end

