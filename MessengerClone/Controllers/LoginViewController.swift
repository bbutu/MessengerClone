//
//  LoginViewController.swift
//  MessengerClone
//
//  Created by Beka Buturishvili on 11.04.23.
//

import UIKit
import FirebaseAuth

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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Log In"
        configureNavBar()
        addSubviews()
        loginButton.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = view.width / 4
        imageView.frame = CGRect(x: (scrollView.width - size) / 2, y: 20, width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.bottom + 30, width: scrollView.width - 60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 10, width: scrollView.width - 60, height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52)
    }
    
    private func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
    }
    
    private func configureNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
    }
    
    @objc private func didTapLoginButton() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            guard let result = authResult, error == nil else {
                print("Failed to log in with email: \(email)")
                return
            }
            let user = result.user
            print("Logged in user: \(user)")
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
