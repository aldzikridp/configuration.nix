{
 programs.wofi = {
  enable = true;
  settings = {
    mode = "run";
    width = 500;
  };
  style = ''
  window {
    background-color: rgba(0,0,0,0.9);
    font-family: RobotoMono Nerd Font;
    transition: 1s ease-in-out;
    color: rgba(228, 228, 228, 1);
  }
  #input image {
      color: rgba(0,0,0,0)
  }
  #input {
      background-color: rgba(255, 255, 255, 0.2);
      margin-bottom: 20px;
      margin-left: 100px;
      margin-right: 100px;
      margin-top: 10px;
      box-shadow: none;
      border: 0px solid;
      border-radius: 0px;
      transition: 0.5s ease-in-out;
  }
  #input:focus {
      background-color: rgba(255, 255, 255, 1);
      margin-left: 10px;
      margin-right: 10px;
      transition: 0.3s ease-in-out;
      border: none;
  }
  /* label {
      color: --wofi-color13;
      transition: 0.5s ease-in-out;
  } */
  #outer-box {
      border: none;
      transition: 0.5s ease-in-out;
  }
  #entry:selected {
      background-color: rgba(255, 255, 255, 1);
      transition: none;
  }
  #text:selected {
      color: rgba(0,0,0,1);
  }
  '';
 };
}
