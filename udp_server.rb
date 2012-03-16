require 'socket'

BasicSocket.do_not_reverse_lookup = true

client = UDPSocket.new
client.bind('0.0.0.0', 33333)

mates = {}

loop do
  data, addr = client.recvfrom(1024) # if this number is too low it will drop the larger packets and never give them to you

  data.strip!

  puts "From addr: (#{ addr.join ',' }), msg: '#{ data }'"

  regexes = { :login => /^LOGIN\s+(\w+)$/, :list => /^LIST$/, :private => /MSG\s+(\w+)\s+(.+)$/ }

  if data =~ regexes[:login] and !mates.has_key?(addr) then
    nickname = regexes[:login].match(data)[1]

    mates.each do |mate_addr, mate_nick|
      client.send("OP: #{ nickname } joins chat", 0, mate_addr[3], mate_addr[1])
    end

    mates[addr] = nickname
    client.send("WELCOME", 0, addr[3], addr[1])
  elsif data =~ regexes[:login] and (mates.has_key?(addr) or mates.has_value?(regexes[:login].match(data)[1])) then
    client.send("BUSYNAME #{ regexes[:login].match(data)[1] } #{ addr.join ',' }", 0, addr[3], addr[1])
  elsif data =~ regexes[:private] and mates.has_value?(regexes[:private].match(data)[1]) then
    nickname = mates[addr]
    mate_nick = regexes[:private].match(data)[1]
    mate_addr = mates.key(mate_nick)
    mate_msg = regexes[:private].match(data)[2]
    client.send("(#{ nickname }): #{ mate_msg }", 0, mate_addr[3], mate_addr[1])
  elsif data =~ regexes[:list] then
    list = []

    mates.each do |k, v|
      list << "#{ v } ( #{ k[3] }:#{ k[1] } )"
    end

    client.send("#{ list.join ', ' }", 0, addr[3], addr[1])
  elsif !(data =~ regexes[:login]) and mates.has_key?(addr) then
    mates.each do |mate_addr, mate_nick|
      #next if mate_addr == addr

      nickname = mates[addr]
      client.send("#{ nickname }: #{ data }", 0, mate_addr[3], mate_addr[1])
    end
  end
end

client.close
