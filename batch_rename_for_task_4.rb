#result = Dir["4/*.dat"]
#result = result.map{|x| x.gsub("4/", "")}
#print result.map{|x|
#	name = Kernel.sprintf("%02d", x.gsub(".dat","").to_i)
#	File.rename("4/" + x, "4/" + name)
#}

result = Dir["4/*.ans"]
result = result.map{|x| x.gsub("4/", "")}
print result.map{|x|
	name = Kernel.sprintf("%02d", x.gsub(".ans","").to_i)
	File.rename("4/" + x, "4/" + name + ".a")
}