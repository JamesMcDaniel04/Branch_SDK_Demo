// Wait for the page to load, then initialize Branch
document.addEventListener('DOMContentLoaded', function() {
  branch.init('key_live_gFCda8Aet0YzyHBUFri9emppxAfS9xt0', function(err, data) {
    if (err) {
      console.error('Branch initialization error:', err);
    } else {
      console.log('Branch initialized successfully:', data);
      
      // Your app logic here
      handleBranchData(data);
    }
  });
});

function handleBranchData(data) {
  // Check if user came from a Branch link
  if (data.data_parsed) {
    console.log('User came from Branch link with data:', data.data_parsed);
    // Handle deep link data
  }
  
  // Check if user has your app installed
  if (data.has_app) {
    console.log('User has the app installed');
  }
}