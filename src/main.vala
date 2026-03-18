using Gtk;

namespace Clicker {
  public class Application : Adw.Application {
    public Application () {
      Object (
        application_id: "com.github.yamada.vala-clicker",
        flags: ApplicationFlags.DEFAULT_FLAGS
      );
    }

    protected override void activate () {
      var window = this.active_window;
      if (window == null) {
        window = new Window (this);
      }
      window.present ();
    }

    public static int main (string[] args) {
      var app = new Application ();
      return app.run (args);
    }
  }
}
