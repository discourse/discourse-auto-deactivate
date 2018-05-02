# discourse-auto-deactivate
This plugin will automatically deactivate stale users so that they need to recomfirm their email in order to login in again.

This plugin is disabled by default, make sure to enable it in your site settings.

### How to install

[How to install a plugin](https://meta.discourse.org/t/install-a-plugin/19157)

### How to run tests

Make sure the plugin has been installed, then from the discourse directory run:

    LOAD_PLUGINS=1 bundle exec rspec plugins/discourse-auto-deactivate/spec/plugin_spec.rb
