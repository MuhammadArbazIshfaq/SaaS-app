// Profile Edit Form JavaScript
document.addEventListener("DOMContentLoaded", function () {
  // Only run on profile edit page
  if (!document.querySelector(".profile-form")) return;

  // Initialize tooltips
  var tooltipTriggerList = [].slice.call(
    document.querySelectorAll('[data-bs-toggle="tooltip"]')
  );
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });

  // Add form validation feedback
  const form = document.querySelector(".profile-form");
  const inputs = form.querySelectorAll(".form-input");

  inputs.forEach((input) => {
    input.addEventListener("blur", function () {
      if (this.value.trim() !== "") {
        this.classList.add("is-valid");
        this.classList.remove("is-invalid");
      }
    });

    input.addEventListener("input", function () {
      if (this.classList.contains("is-invalid")) {
        this.classList.remove("is-invalid");
      }
    });
  });

  // Add loading animation to submit button
  form.addEventListener("submit", function () {
    const submitBtn = form.querySelector(".update-btn");
    submitBtn.innerHTML =
      '<i class="bi bi-arrow-clockwise spin me-2"></i>Updating...';
  });
});
