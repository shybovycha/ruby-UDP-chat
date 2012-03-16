require 'gtk2'
require 'thread'
require 'socket'

class MooChat
	public
		def initialize(host, port)
			@builder = Gtk::Builder::new
			@mutex = Mutex.new

			@sock = UDPSocket.new

			@builder << 'moochat_form.glade'
			@builder.connect_signals { |handler| method(handler) }

			@host = host
			@port = port

			init_udp

			Gtk.init()
				entry = @builder.get_object('entry1')
				entry.grab_focus

				window = @builder.get_object('window1')
				window.signal_connect('delete_event') { exit_func }
				window.set_title "mooChat!"
				window.show()
			Gtk.main()
		end

	private
		def exit_func
			Gtk.main_quit
			@sock.close
		end

		def init_udp
			Thread.new do
				loop do
					data, addr = @sock.recvfrom(1024)
					data.strip!

					add_text(data)
				end
			end
		end

		def add_text(text)
			text_view = @builder.get_object('textview1')
			text_view.buffer.insert(text_view.buffer.end_iter, text + "\n")
			text_view.scroll_to_iter(text_view.buffer.end_iter, 0.1, true, 0, 0)
		end

		def send_text(text)
			@sock.send(text.strip, 0, @host, @port)
		end

		def send_message(sender)
			@mutex.synchronize do
				entry = @builder.get_object('entry1')
				text = entry.text

				send_text(text)

				entry.text = ''
			end
		end
end

MooChat.new(ARGV[0], ARGV[1])
