// Simple test file to check if JavaScript is loading
console.log("Test JavaScript file loaded successfully!");

document.addEventListener("DOMContentLoaded", function () {
  console.log("DOMContentLoaded event fired in test file");
});

document.addEventListener("turbo:load", function () {
  console.log("Turbo:load event fired in test file");
});
