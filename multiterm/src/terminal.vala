using Gtk;
using Gdk;
using Vte;

namespace MultiTerm
{
	public class Terminal : Frame
	{
		public Vte.Terminal terminal;
		private ShellConfig sh;

		public signal bool right_click_event(EventButton event);

		private void on_window_title_changed()
		{
			tab_label_text = terminal.window_title;
		}

		public string tab_label_text
		{
			get
			{
				TabLabel label = this.get_data<TabLabel>("label");
				return label.text;
			}
			set
			{
				TabLabel label = this.get_data<TabLabel>("label");
				label.text = value;
			}
		}

		public string background_color
		{
			set
			{
				Gdk.Color color = Gdk.Color();
				Gdk.Colormap.get_system().alloc_color(color, true, true);
				Gdk.Color.parse(value, out color);
				terminal.set_color_background(color);
			}
		}

		public string foreground_color
		{
			set
			{
				Gdk.Color color = Gdk.Color();
				Gdk.Colormap.get_system().alloc_color(color, true, true);
				Gdk.Color.parse(value, out color);
				terminal.set_color_foreground(color);
			}
		}

		public void run_command(string command)
		{
			Pid pid;
			string[] argv = { command, null };
			try
			{
				terminal.fork_command_full(PtyFlags.DEFAULT, null, argv, null,
					SpawnFlags.SEARCH_PATH, null, out pid);
				//debug("Started terminal with pid of '%d'", pid);
			}
			catch (Error err)
			{
				warning("Unable to run command: %s", err.message);
			}
		}

		private void on_vte_realize()
		{
			if (sh.cfg != null)
			{
				background_color = sh.background_color;
				foreground_color = sh.foreground_color;
			}
			else
			{
				background_color = "#ffffff";
				foreground_color = "#000000";
			}

			/* Start receiving events for mouse clicks */
			terminal.add_events(EventMask.BUTTON_PRESS_MASK);
			terminal.button_press_event.connect(on_button_press);
		}

		private void on_child_exited()
		{
			run_command(this.sh.command);
		}

		private bool on_button_press(EventButton event)
		{
			if (event.button == 3)
				return right_click_event(event);
			return false;
		}

		public void send_command(string command)
		{
			terminal.feed_child("%s\n".printf(command), -1);
		}

		public Terminal(ShellConfig sh)
		{
			VScrollbar vsb;
			HBox hbox;

			this.sh = sh;
            if (this.sh.command.strip() == "")
				this.sh.command = "sh";

			terminal = new Vte.Terminal();
			terminal.set_size_request(100, 100); // stupid
			terminal.show_all();

			vsb = new VScrollbar(terminal.get_adjustment());
			hbox = new HBox(false, 0);

			hbox.pack_start(terminal, true, true, 0);
			hbox.pack_start(vsb, false, false, 0);

			this.add(hbox);

			if (this.sh.track_title)
				terminal.window_title_changed.connect(on_window_title_changed);

			terminal.child_exited.connect(on_child_exited);

			if (this.sh.cfg != null)
				terminal.set_font_from_string_full(this.sh.font, TerminalAntiAlias.FORCE_ENABLE);
			else
				terminal.set_font_from_string_full("Monospace 9", TerminalAntiAlias.FORCE_ENABLE);

			terminal.realize.connect(on_vte_realize); /* colors can only be set on realize (lame) */
			run_command(this.sh.command);
		}

	}
}
