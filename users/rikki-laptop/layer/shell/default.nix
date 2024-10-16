{...} @ upstream: let
  trackerList = import ./aria2-tracker;
  args =
    {
      inherit trackerList;
    }
    // upstream;
in {
  specialArgs = {inherit args;};
  imports = [
    ./fish
    ./bash
  ];
}
