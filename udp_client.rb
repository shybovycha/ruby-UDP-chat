require 'socket'

sock = UDPSocket.new

Thread.new do
	loop do
		data, addr = sock.recvfrom(1024)
		data.strip!
		puts data
	end
end

loop do
	data = gets.strip
	sock.send(data, 0, '127.0.0.1', 33333)
end

sock.close
