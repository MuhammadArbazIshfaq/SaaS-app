// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

// Configure Turbo to handle method: :delete and confirmations
import { Turbo } from "@hotwired/turbo-rails";

// Enable Turbo for the entire application
Turbo.start();
