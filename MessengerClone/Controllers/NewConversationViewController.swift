//
//  NewConversationViewController.swift
//  MessengerClone
//
//  Created by Beka Buturishvili on 11.04.23.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    private var users = [[String : String]]()
    
    private var results = [[String : String]]()
    
    private var hasFetched = false
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for users..."
        return searchBar
    }()
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.text = "No Results"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.textColor = .label
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addSubviews()
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(didTapCancelButton))
        searchBar.becomeFirstResponder()
        configureConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func configureConstraints() {
        let noResultsLabelConstraints = [
            noResultsLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 300),
            noResultsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            noResultsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            noResultsLabel.heightAnchor.constraint(equalToConstant: 50)
        ]
        
        NSLayoutConstraint.activate(noResultsLabelConstraints)
    }
    
    @objc private func didTapCancelButton() {
        dismiss(animated: true)
    }
    
    private func addSubviews() {
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
    }
    
}

extension NewConversationViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        results.removeAll()
        spinner.show(in: view)
        self.searchUsers(query: text)
    }
    
    private func searchUsers(query: String) {
        // check if array has firebase results
        if hasFetched {
            //if it does, filter
            self.filterUsers(with: query)
        } else  {
            //if not, fetch then filter
            DatabaseManager.shared.getAllUsers { [weak self]  result in
                switch result {
                case .success(let usersCollection):
                    self?.users = usersCollection
                    self?.hasFetched = true
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("Failed to fetch all users data with error: \(error)")
                }
            }
        }
    }
    
    private func filterUsers(with term: String) {
        guard hasFetched == true else {
            return
        }
        self.spinner.dismiss()
        let results: [[String : String]] = self.users.filter {
            guard let name = $0["name"]?.lowercased() as? String else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }
        self.results = results
        updateUI()
    }
    
    private func updateUI() {
        if(results.isEmpty) {
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        } else {
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
    
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //Start new conversation.
    }
}
