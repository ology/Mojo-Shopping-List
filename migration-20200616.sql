DROP TABLE item_counts;
CREATE TABLE item_counts (
  id INTEGER PRIMARY KEY NOT NULL,
  count INTEGER NOT NULL,
  account_id INTEGER NOT NULL,
  item_id INTEGER NOT NULL,
  FOREIGN KEY (item_id) REFERENCES items(id)
);
CREATE INDEX item_counts_idx_item_id ON item_counts (item_id);
