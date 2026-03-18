using Gtk;

namespace Clicker {
  public class Window : Gtk.ApplicationWindow {
    private int count = 0;
    private Label label;

    public Window (Gtk.Application app) {
      Object (application: app, title: "Vala Clicker");

      this.set_default_size (300, 200);

      var box = new Box (Orientation.VERTICAL, 12);
      box.set_margin_top (24);
      box.set_margin_bottom (24);
      box.set_margin_start (24);
      box.set_margin_end (24);
      box.set_valign (Align.CENTER);
      box.set_halign (Align.CENTER);

      label = new Label (count.to_string ());
      label.add_css_class ("title-1");

      var button = new Button.with_label ("Click Me!");
      button.add_css_class ("suggested-action");
      button.clicked.connect (() => {
        count++;
        label.set_label (count.to_string ());
      });

      box.append (label);
      box.append (button);

      this.set_child (box);
    }
  }
}
