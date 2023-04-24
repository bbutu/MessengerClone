//
//  LoginViewController.swift
//  MessengerClone
//
//  Created by Beka Buturishvili on 11.04.23.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import FirebaseCore
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let emailField: UITextField = {
        let field = ReusableTextField()
        field.returnKeyType = .continue
        field.placeholder = "Email Address..."
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = ReusableTextField()
        field.returnKeyType = .done
        field.isSecureTextEntry = true
        field.placeholder = "Password..."
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = ReusableButton()
        button.setTitle("Log In", for: .normal)
        return button
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    private let googleLoginButton = GIDSignInButton()
    
    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Log In"
        configureNavBar()
        addSubviews()
        loginButton.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        facebookLoginButton.delegate = self
        googleLoginButton.addTarget(self, action: #selector(didTapGoogleLoginButton), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = view.width / 4
        imageView.frame = CGRect(x: (scrollView.width - size) / 2, y: 20, width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.bottom + 30, width: scrollView.width - 60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 10, width: scrollView.width - 60, height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52)
        facebookLoginButton.frame = CGRect(x: 30, y: loginButton.bottom + 10, width: scrollView.width - 60, height: 52)
        facebookLoginButton.layer.cornerRadius = 12
        googleLoginButton.frame = CGRect(x: 30, y: facebookLoginButton.bottom + 10, width: scrollView.width - 60, height: 52)
        googleLoginButton.layer.cornerRadius = 12
    }
    
    private func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLoginButton)
    }
    
    private func configureNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
    }
    
    @objc private func didTapGoogleLoginButton() {
        signInWithGoogle()
    }
    
    @objc private func didTapLoginButton() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) {[weak self] authResult, error in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            guard let result = authResult, error == nil else {
                print("Failed to log in with email: \(email)")
                return
            }
            let user = result.user
            print("Logged in user: \(user)")
            strongSelf.navigationController?.dismiss(animated: true)
        }
    }
    
    private func alertUserLoginError() {
        let alert = UIAlertController(title: "Whoops...", message: "Please enter all information to log in", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }else if textField == passwordField {
            didTapLoginButton()
        }
        return true
    }
}

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // nothing to do
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields":
                                                                            "email,first_name,last_name,picture.type(large)"],
                                                         tokenString: token, version: nil, httpMethod: .get)
        facebookRequest.start { _, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("faield to make facebook graph request")
                return
            }
            
            print(result)
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String : Any],
                  let data = picture["data"] as? [String : Any],
                  let pictureURL = data["url"] as? String else {
                print("Failed to get user email and name from facebook")
                return
            }
            
            DatabaseManager.shared.userExists(with: email) { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser) { success in
                        if(success) {
                            // upload image
                            guard let url = URL(string: pictureURL) else {
                                return
                            }
                            
                            print("Downloading data from facebook image")
                            
                            URLSession.shared.dataTask(with: url) { data, _ , _ in
                                guard let data = data else {
                                    print("Failed to get data from Facebook")
                                    return
                                }
                                
                                print("got data from FB, uploading..")
                                
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                                    switch result {
                                    case .success(let downloadURL):
                                        UserDefaults.standard.set(downloadURL, forKey: "profile_picture_url")
                                        print(downloadURL)
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                }
                            } .resume()
                        }
                    }
                }
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential) {[weak self] authResult, error in
                guard let strongSelf = self else {return}
                guard authResult != nil, error == nil else {
                    print("Facebook credential login failed, MFA may be needed")
                    return
                }
                print("user successfully logged in")
                strongSelf.navigationController?.dismiss(animated: true)
            }
        }
    }
}

extension LoginViewController {
    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, error in
            guard error == nil else {
                
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
            else {
                print("Error while signing in with Google: \(String(describing: error?.localizedDescription))")
                return
            }
            
            guard let email = user.profile?.email,
                  let firstName = user.profile?.givenName,
                  let lastName = user.profile?.familyName else {
                return
            }
            print("Did sign in with user: \(user)")
            DatabaseManager.shared.userExists(with: email) { exists in
                if !exists {
                    //inserts to database
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser) { success in
                        if(success) {
                            guard let profile = user.profile else {return}
                            if profile.hasImage {
                                guard let url = user.profile?.imageURL(withDimension: 200) else {
                                    print("Error getting url from google.")
                                    return
                                }
                                URLSession.shared.dataTask(with: url) { data, _, _ in
                                    guard let data = data else {
                                        return
                                    }
                                    
                                    // upload image
                                    let fileName = chatUser.profilePictureFileName
                                    StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                                        switch result {
                                        case .success(let downloadURL):
                                            UserDefaults.standard.set(downloadURL, forKey: "profile_picture_url")
                                            print(downloadURL)
                                        case .failure(let error):
                                            print("Storage manager error: \(error)")
                                        }
                                    }
                                } .resume()
                            }
                        } 
                    }
                }
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            FirebaseAuth.Auth.auth().signIn(with: credential) {[weak self] authResult, error in
                guard let strongSelf = self else {return}
                guard authResult != nil, error == nil else {
                    print("Failed to log in google with credential")
                    return
                }
                strongSelf.navigationController?.dismiss(animated: true)
                print("Successfully signed in with Google Credential.")
            }
        }
    }
}
