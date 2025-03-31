from . import db

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(100), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)

    def __repr__(self):
        return f"<User {self.username}>"

class Folder(db.Model):
    __tablename__ = 'folders'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    asset_count = db.Column(db.Integer, default=0)  # The number of assets in the folder
    restored_asset_count = db.Column(db.Integer, default=0)
    size = db.Column(db.Integer, default=0)  # Total size of assets in the folder (in bytes)
    is_deleted = db.Column(db.Boolean, default=False)  # Whether the folder is deleted
    is_archived = db.Column(db.Boolean, default=False)  # Whether the folder is archived
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())
    updated_at = db.Column(db.DateTime, default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())

    user = db.relationship('User', backref=db.backref('folders', lazy=True))

    def __repr__(self):
        return f'<Folder {self.name}>'
