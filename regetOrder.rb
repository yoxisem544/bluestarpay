require 'digest/md5'
require 'rest_client'
require 'nokogiri'
require 'iconv'

code = "abcd1234"
postUrl = "http://testmaple2.neweb.com.tw/CashSystemFrontEnd/Query"

postData = {
	# 可以選big-5, UTF-8
	:responseencoding => "UTF-8",
	# 無意義轉跳網址。
	:nexturl => "",
	# 這欄固定是 regetorder
	:operation => "regetorder",
	# 1 => 回傳一段url給我們解析
	:returnvalue => "1",
	# 等一下會包起來兒
	:hash => "",
	# 付款方式，固定為MMK
	:paymenttype => "MMK",
	# 金額
	:amount => "14000",
	# 訂單編號
	:ordernumber => "101029290140",
	# 米斯克 商店編號
	:merchantnumber => "460172",
	# 這欄空下不填
	:bankid => ""
}

# hash = md5(merchantnumber+code+amount+ordernumber)

postData[:hash] = Digest::MD5.hexdigest(postData[:merchantnumber]+code+postData[:amount]+postData[:ordernumber])

# puts postData[:hash]
r = RestClient.post postUrl, postData
ic = Iconv.new("utf-8//translit//IGNORE","UTF-8")
n = Nokogiri::HTML(ic.iconv(r.to_s))

# puts n.css('p').text.split('&')
response = n.css('p').text.split('&')

if response[0].split('=').last == "0"
	puts "OK"
	puts "繳費代碼 " + response[4].split('=').last
elsif response[0].split('=').last == "-4"
	puts "已經完成繳費" if response[1].split('=').last == "72"
	puts "無此筆訂單！" if response[1].split('=').last == "71"
	puts "金額不符" if response[1].split('=').last == "33"
	puts "hash 驗證碼錯誤" if response[1].split('=').last == "39"
end
		